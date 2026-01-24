import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voter.dart';
import '../helpers/database_helper.dart';
import '../services/transliteration_service.dart';
import '../services/search_service.dart';
import '../providers/filter_provider.dart';
import '../helpers/text_helper.dart';
import '../models/search_models.dart';
import '../providers/voter_search_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Analytics provider – recomputes when filter changes
// ─────────────────────────────────────────────────────────────────────────────

final analyticsDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final voterState = ref.watch(voterProvider);
  final notifier = ref.read(voterProvider.notifier);

  // If we have search results, use analytics based on the current displayed data
  if (voterState.isClientSidePagination && voterState.allVoters.isNotEmpty) {
    // For search results, calculate analytics from the current search results
    return notifier.getAnalyticsDataFromVoters(voterState.allVoters);
  } else {
    // For regular filters, use the filter-based analytics
    final filter = ref.watch(filterProvider);
    return notifier.getAnalyticsData(filter: filter);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Total count provider – depends on current filter
// ─────────────────────────────────────────────────────────────────────────────

final totalVoterCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final filter = ref.watch(filterProvider);
  final notifier = ref.read(voterProvider.notifier);
  return notifier.getTotalCount(filter: filter);
});

// ─────────────────────────────────────────────────────────────────────────────
// Main categories provider
// ─────────────────────────────────────────────────────────────────────────────

final mainCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final dbHelper = DatabaseHelper.instance;
  return dbHelper.getMainEthnicCategories();
});

// ─────────────────────────────────────────────────────────────────────────────
// Main Voter State & Notifier
// ─────────────────────────────────────────────────────────────────────────────

class VoterState {
  final List<Voter> voters; // Current page voters (shown)
  final List<Voter> allVoters; // All loaded voters for client-side pagination
  final bool isLoading;
  final int pageSize;
  final int currentPage;
  final int totalPages;
  final FilterState? currentFilter;
  final Map<String, Map<String, dynamic>> analyticsCache;
  final int? cachedTotalCount;
  final bool isAnalyticsLoading;
  final String? analyticsError;
  final String? loadingError;
  final bool isInitialLoad; // Track if we've done the initial full load
  final bool
  isClientSidePagination; // Whether we're using client-side pagination

  VoterState({
    this.voters = const [],
    this.allVoters = const [],
    this.isLoading = false,
    this.pageSize = 100,
    this.currentPage = 1,
    this.totalPages = 1,
    this.currentFilter,
    this.analyticsCache = const {},
    this.cachedTotalCount,
    this.isAnalyticsLoading = false,
    this.analyticsError,
    this.loadingError,
    this.isInitialLoad = false,
    this.isClientSidePagination = false,
  });

  VoterState copyWith({
    List<Voter>? voters,
    List<Voter>? allVoters,
    bool? isLoading,
    int? pageSize,
    int? currentPage,
    int? totalPages,
    FilterState? currentFilter,
    Map<String, Map<String, dynamic>>? analyticsCache,
    int? cachedTotalCount,
    bool? isAnalyticsLoading,
    String? analyticsError,
    String? loadingError,
    bool? isInitialLoad,
    bool? isClientSidePagination,
  }) {
    return VoterState(
      voters: voters ?? this.voters,
      allVoters: allVoters ?? this.allVoters,
      isLoading: isLoading ?? this.isLoading,
      pageSize: pageSize ?? this.pageSize,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentFilter: currentFilter ?? this.currentFilter,
      analyticsCache: analyticsCache ?? this.analyticsCache,
      cachedTotalCount: cachedTotalCount ?? this.cachedTotalCount,
      isAnalyticsLoading: isAnalyticsLoading ?? this.isAnalyticsLoading,
      analyticsError: analyticsError ?? this.analyticsError,
      loadingError: loadingError ?? this.loadingError,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      isClientSidePagination:
          isClientSidePagination ?? this.isClientSidePagination,
    );
  }

  bool get canGoPrevious => currentPage > 1;
  bool get canGoNext => currentPage < totalPages;
}

class VoterNotifier extends StateNotifier<VoterState> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TransliterationService _transliteration = TransliterationService();
  final SearchService _searchService;

  // Pending query for decoupled search
  String _pendingQuery = '';

  static const List<String> _groupByOptions = [
    'province',
    'district',
    'municipality',
    'ward',
    'booth',
  ];

  VoterNotifier(this._searchService) : super(VoterState());

  // ────────────────────────────────────────────────────────────────────────────
  // Core loading logic
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> loadVoters() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, loadingError: null);
    debugPrint('VoterNotifier: Loading voters (page ${state.currentPage})');

    try {
      final filter = state.currentFilter ?? const FilterState();

      // Check if there's an active search in the filter (from previous search)
      if (filter.searchQuery?.isNotEmpty == true) {
        // This is a refresh with active search - call performSearch to restore search results
        debugPrint(
          'VoterNotifier: Restoring search results for query: ${filter.searchQuery}',
        );
        await performSearch(
          query: filter.searchQuery,
          field: filter.searchField,
          matchMode: filter.searchMatchMode,
        );
        return;
      }

      // Apply search if searchQuery is present
      String? searchQuery;
      if (filter.searchQuery?.isNotEmpty == true) {
        final effectiveField = filter.searchField ?? SearchField.name;
        final effectiveMatchMode =
            filter.searchMatchMode ?? SearchMatchMode.startsWith;

        final queryValue = effectiveField == SearchField.voterId
            ? filter.searchQuery!
            : filter.searchQuery!;

        // For name search, try transliteration and handle variations
        if (effectiveField == SearchField.name) {
          // Try to transliterate English to Nepali
          String transliteratedQuery = await _transliteration
              .transliterateToNepali(queryValue);

          // Use the transliterated version if it's different, otherwise use original
          searchQuery = transliteratedQuery.isNotEmpty
              ? transliteratedQuery
              : queryValue;
        } else {
          searchQuery = queryValue;
        }

        // Create search pattern based on match mode
        searchQuery = effectiveMatchMode == SearchMatchMode.startsWith
            ? '$searchQuery%'
            : '%$searchQuery%';
      }

      // Get total count first (without pagination)
      final totalRows = await _dbHelper.getVoters(
        searchQuery: searchQuery,
        startingLetter: filter.startingLetter,
        provinceId: await _getProvinceId(filter.province),
        districtId: await _getDistrictId(filter.district),
        municipalityId: await _getMunicipalityId(filter.municipality),
        wardNo: filter.wardNo,
        boothCode: filter.boothCode,
        gender: filter.gender,
        minAge: filter.minAge,
        maxAge: filter.maxAge,
        mainCategory: filter.mainCategory,
        limit: null,
        offset: null,
      );

      final totalCount = totalRows.length;
      final totalPages = state.pageSize == -1
          ? 1
          : (totalCount / state.pageSize).ceil();

      // Check if we should use client-side pagination (for small datasets)
      const int maxClientSideCount =
          50000; // Max records for client-side pagination
      final shouldUseClientSide =
          totalCount <= maxClientSideCount && totalCount > 0;

      if (shouldUseClientSide) {
        // Load all data for client-side pagination
        final allVoters = totalRows.map((row) => Voter.fromMap(row)).toList();

        // Calculate current page voters
        final startIndex = (state.currentPage - 1) * state.pageSize;
        final endIndex = startIndex + state.pageSize;
        final pageVoters = allVoters.sublist(
          startIndex,
          endIndex > allVoters.length ? allVoters.length : endIndex,
        );

        state = state.copyWith(
          voters: pageVoters,
          allVoters: allVoters,
          totalPages: totalPages,
          cachedTotalCount: totalCount,
          isLoading: false,
          isInitialLoad: true,
          isClientSidePagination: true,
        );

        debugPrint(
          'Loaded all ${allVoters.length} voters for client-side pagination (showing page ${state.currentPage}/${totalPages})',
        );
      } else {
        // Database pagination for large datasets
        final offset = state.pageSize == -1
            ? null
            : (state.currentPage - 1) * state.pageSize;
        final limit = state.pageSize == -1 ? null : state.pageSize;

        final rows = await _dbHelper.getVoters(
          searchQuery: searchQuery,
          startingLetter: filter.startingLetter,
          provinceId: await _getProvinceId(filter.province),
          districtId: await _getDistrictId(filter.district),
          municipalityId: await _getMunicipalityId(filter.municipality),
          wardNo: filter.wardNo,
          boothCode: filter.boothCode,
          gender: filter.gender,
          minAge: filter.minAge,
          maxAge: filter.maxAge,
          mainCategory: filter.mainCategory,
          limit: limit,
          offset: offset,
        );

        final newVoters = rows.map((row) => Voter.fromMap(row)).toList();

        state = state.copyWith(
          voters: newVoters,
          totalPages: totalPages,
          cachedTotalCount: totalCount,
          isLoading: false,
          isInitialLoad: true,
          isClientSidePagination: false,
        );

        debugPrint(
          'Loaded ${newVoters.length} voters (page ${state.currentPage}/${totalPages}) | Total: $totalCount',
        );
      }
    } catch (e, stack) {
      debugPrint('VoterNotifier load error: $e\n$stack');
      state = state.copyWith(isLoading: false, loadingError: e.toString());
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Search functionality (triggered by search button)
  // ────────────────────────────────────────────────────────────────────────────

  // Method to update pending query without triggering search
  void updateQuery(String val) {
    _pendingQuery = val;
  }

  // Method to perform search using the pending query
  Future<void> performSearch({
    String? query,
    SearchField? field,
    SearchMatchMode? matchMode,
  }) async {
    final effectiveQuery = query ?? _pendingQuery;
    if (effectiveQuery.isEmpty) {
      // Clear results if search query is empty
      state = state.copyWith(
        voters: [],
        currentPage: 1,
        totalPages: 1,
        cachedTotalCount: 0,
        isLoading: false,
      );
      return;
    }

    // Clear previous results before starting new search
    state = state.copyWith(
      voters: [],
      currentPage: 1,
      cachedTotalCount: null,
      isLoading: true,
      loadingError: null,
    );
    clearAnalyticsCache();

    try {
      final filter = state.currentFilter ?? const FilterState();

      final effectiveField = field ?? filter.searchField ?? SearchField.name;
      final effectiveMatchMode =
          matchMode ?? filter.searchMatchMode ?? SearchMatchMode.startsWith;

      // Use SearchService to perform the search
      final searchResults = await _searchService.performSearch(
        query: effectiveQuery,
        field: effectiveField as SearchField,
        matchMode: effectiveMatchMode as SearchMatchMode,
        province: filter.province,
        district: filter.district,
        municipality: filter.municipality,
        wardNo: filter.wardNo?.toString(),
        boothCode: filter.boothCode,
        gender: filter.gender,
        minAge: filter.minAge,
        maxAge: filter.maxAge,
        mainCategory: filter.mainCategory,
        limit: 10000, // Limit for search results
      );

      final totalCount = searchResults.length;
      final totalPages = state.pageSize == -1
          ? 1
          : (totalCount / state.pageSize).ceil();

      // Paginate search results
      final startIndex = 0;
      final endIndex = state.pageSize == -1 ? totalCount : state.pageSize;
      final pageVoters = searchResults.sublist(startIndex, endIndex);

      // Update the filter with search parameters to persist search state
      final updatedFilter = (state.currentFilter ?? const FilterState())
          .copyWith(
            searchQuery: effectiveQuery,
            searchField: effectiveField as SearchField?,
            searchMatchMode: effectiveMatchMode as SearchMatchMode?,
          );

      state = state.copyWith(
        voters: pageVoters,
        allVoters:
            searchResults, // Store all results for client-side pagination
        totalPages: totalPages,
        cachedTotalCount: totalCount,
        currentFilter: updatedFilter,
        isLoading: false,
        isInitialLoad: true,
        isClientSidePagination:
            true, // Enable client-side pagination for search results
      );

      debugPrint(
        'Search completed: Found ${searchResults.length} voters (showing ${pageVoters.length} on page ${state.currentPage}/${totalPages})',
      );
    } catch (e, stack) {
      debugPrint('Search error: $e\n$stack');
      state = state.copyWith(isLoading: false, loadingError: e.toString());
    }
  }

  // Helper method to check if filters have changed
  bool _hasFilterChanged(FilterState newFilter) {
    final currentFilter = state.currentFilter ?? const FilterState();
    return currentFilter.province != newFilter.province ||
        currentFilter.district != newFilter.district ||
        currentFilter.municipality != newFilter.municipality ||
        currentFilter.wardNo != newFilter.wardNo ||
        currentFilter.boothCode != newFilter.boothCode ||
        currentFilter.gender != newFilter.gender ||
        currentFilter.minAge != newFilter.minAge ||
        currentFilter.maxAge != newFilter.maxAge ||
        currentFilter.startingLetter != newFilter.startingLetter;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Filter & reload
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> applyFiltersAndReload(FilterState filter) async {
    // Handle multi-select vs single-select logic
    FilterState effectiveFilter = filter;

    // If using advanced mode with multi-select, we need to handle it differently
    // For now, we'll use the first selected item from multi-select as the filter
    // or combine them appropriately
    if (filter.selectedProvinces?.isNotEmpty == true ||
        filter.selectedDistricts?.isNotEmpty == true ||
        filter.selectedMunicipalities?.isNotEmpty == true ||
        filter.selectedWards?.isNotEmpty == true ||
        filter.selectedBooths?.isNotEmpty == true) {
      // For multi-select, we need to modify the query to handle multiple values
      // For now, let's use the first selected item to avoid crashes
      effectiveFilter = FilterState(
        province: filter.selectedProvinces?.isNotEmpty == true
            ? filter.selectedProvinces!.first
            : filter.province,
        district: filter.selectedDistricts?.isNotEmpty == true
            ? filter.selectedDistricts!.first
            : filter.district,
        municipality: filter.selectedMunicipalities?.isNotEmpty == true
            ? filter.selectedMunicipalities!.first
            : filter.municipality,
        wardNo: filter.selectedWards?.isNotEmpty == true
            ? filter.selectedWards!.first
            : filter.wardNo,
        boothCode: filter.selectedBooths?.isNotEmpty == true
            ? filter.selectedBooths!.first
            : filter.boothCode,
        gender: filter.gender,
        minAge: filter.minAge,
        maxAge: filter.maxAge,
        startingLetter: filter.startingLetter,
        mainCategory: filter.mainCategory,
        searchQuery: filter.searchQuery,
        searchField: filter.searchField,
        searchMatchMode: filter.searchMatchMode,
        // Keep multi-select fields for UI state
        selectedProvinces: filter.selectedProvinces,
        selectedDistricts: filter.selectedDistricts,
        selectedMunicipalities: filter.selectedMunicipalities,
        selectedWards: filter.selectedWards,
        selectedBooths: filter.selectedBooths,
      );
    }

    state = state.copyWith(
      currentFilter: effectiveFilter,
      currentPage: 1,
      cachedTotalCount: null,
    );
    clearAnalyticsCache();
    await loadVoters();
  }

  Future<void> forceReload() async {
    state = state.copyWith(
      isInitialLoad: false,
      currentPage: 1,
      cachedTotalCount: null,
      currentFilter: const FilterState(),
    );
    clearAnalyticsCache();
    await loadVoters();
  }

  void updateVoterInCache(Voter updatedVoter) {
    // Update in current page if present
    final pageIndex = state.voters.indexWhere((v) => v.id == updatedVoter.id);
    if (pageIndex != -1) {
      final updatedPageList = List<Voter>.from(state.voters);
      updatedPageList[pageIndex] = updatedVoter;
      state = state.copyWith(voters: updatedPageList);
    }
  }

  void clearFilters() {
    state = state.copyWith(
      currentFilter: const FilterState(),
      currentPage: 1,
      cachedTotalCount: null,
    );
    clearAnalyticsCache();
    loadVoters();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Pagination (client-side or database)
  // ────────────────────────────────────────────────────────────────────────────

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages || page == state.currentPage)
      return;

    if (state.isClientSidePagination && state.allVoters.isNotEmpty) {
      // Client-side pagination - synchronous
      final startIndex = (page - 1) * state.pageSize;
      final endIndex = startIndex + state.pageSize;
      final pageVoters = state.allVoters.sublist(
        startIndex,
        endIndex > state.allVoters.length ? state.allVoters.length : endIndex,
      );
      state = state.copyWith(currentPage: page, voters: pageVoters);
    } else {
      // Database pagination - async
      state = state.copyWith(currentPage: page);
      loadVoters();
    }
  }

  void nextPage() {
    if (state.canGoNext) {
      goToPage(state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.canGoPrevious) {
      goToPage(state.currentPage - 1);
    }
  }

  Future<void> setPageSize(int size) async {
    if (size == state.pageSize) return;

    if (state.isClientSidePagination && state.allVoters.isNotEmpty) {
      // Recalculate pagination for client-side
      final totalCount = state.allVoters.length;
      final totalPages = size == -1 ? 1 : (totalCount / size).ceil();
      final startIndex = 0;
      final endIndex = size == -1 ? totalCount : size;
      final pageVoters = state.allVoters.sublist(startIndex, endIndex);

      state = state.copyWith(
        pageSize: size,
        currentPage: 1,
        totalPages: totalPages,
        voters: pageVoters,
      );
    } else {
      // Database pagination
      state = state.copyWith(pageSize: size, currentPage: 1);
      await loadVoters();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Analytics
  // ────────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalyticsData({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();
    // final cacheKey = effectiveFilter.toString() + state.groupBy;

    // if (state.analyticsCache.containsKey(cacheKey)) {
    //   return state.analyticsCache[cacheKey]!;
    // }

    final data = await _dbHelper.getAnalyticsData(
      searchQuery: effectiveFilter.searchQuery,
      startingLetter: effectiveFilter.startingLetter,
      provinceId: await _getProvinceId(effectiveFilter.province),
      districtId: await _getDistrictId(effectiveFilter.district),
      municipalityId: await _getMunicipalityId(effectiveFilter.municipality),
      wardNo: effectiveFilter.wardNo,
      boothCode: effectiveFilter.boothCode,
      gender: effectiveFilter.gender,
      minAge: effectiveFilter.minAge,
      maxAge: effectiveFilter.maxAge,
      // groupBy: state.groupBy,
    );

    // state = state.copyWith(
    //   analyticsCache: {...state.analyticsCache, cacheKey: data},
    // );

    return data;
  }

  Future<Map<String, dynamic>> getAnalyticsDataFromVoters(
    List<Voter> voters,
  ) async {
    // Calculate analytics directly from the voter list (for search results)
    final totalVoters = voters.length;

    // Gender distribution
    final maleCount = voters
        .where(
          (v) =>
              v.gender?.toLowerCase() == 'm' ||
              v.gender?.toLowerCase() == 'male',
        )
        .length;
    final femaleCount = voters
        .where(
          (v) =>
              v.gender?.toLowerCase() == 'f' ||
              v.gender?.toLowerCase() == 'female',
        )
        .length;
    final otherGenderCount = totalVoters - maleCount - femaleCount;

    // Age distribution
    final ageGroups = {
      '18-25': voters
          .where((v) => v.age != null && v.age! >= 18 && v.age! <= 25)
          .length,
      '26-35': voters
          .where((v) => v.age != null && v.age! >= 26 && v.age! <= 35)
          .length,
      '36-45': voters
          .where((v) => v.age != null && v.age! >= 36 && v.age! <= 45)
          .length,
      '46-60': voters
          .where((v) => v.age != null && v.age! >= 46 && v.age! <= 60)
          .length,
      '60+': voters.where((v) => v.age != null && v.age! > 60).length,
      'Unknown': voters.where((v) => v.age == null).length,
    };

    // Province distribution
    final provinceGroups = <String, int>{};
    for (final voter in voters) {
      final province = voter.province ?? 'Unknown';
      provinceGroups[province] = (provinceGroups[province] ?? 0) + 1;
    }

    // Main category distribution
    final categoryGroups = <String, int>{};
    for (final voter in voters) {
      final category = voter.mainCategory ?? 'Unknown';
      categoryGroups[category] = (categoryGroups[category] ?? 0) + 1;
    }

    return {
      'total_voters': totalVoters,
      'gender_distribution': {
        'Male': maleCount,
        'Female': femaleCount,
        'Other': otherGenderCount,
      },
      'age_distribution': ageGroups,
      'province_distribution': provinceGroups,
      'category_distribution': categoryGroups,
    };
  }

  Future<int> getTotalCount({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();

    // Build search query for database
    String? searchQuery;
    if (effectiveFilter.searchQuery?.isNotEmpty == true) {
      final effectiveField = effectiveFilter.searchField ?? SearchField.name;
      final effectiveMatchMode =
          effectiveFilter.searchMatchMode ?? SearchMatchMode.startsWith;

      final queryValue = effectiveField == SearchField.voterId
          ? effectiveFilter.searchQuery!
          : effectiveFilter.searchQuery!;
      searchQuery = effectiveMatchMode == SearchMatchMode.startsWith
          ? '$queryValue%'
          : '%$queryValue%';
    }

    // Get total count with all filters applied at database level
    final rows = await _dbHelper.getVoters(
      searchQuery: searchQuery,
      startingLetter: effectiveFilter.startingLetter,
      provinceId: await _getProvinceId(effectiveFilter.province),
      districtId: await _getDistrictId(effectiveFilter.district),
      municipalityId: await _getMunicipalityId(effectiveFilter.municipality),
      wardNo: effectiveFilter.wardNo,
      boothCode: effectiveFilter.boothCode,
      gender: effectiveFilter.gender,
      minAge: effectiveFilter.minAge,
      maxAge: effectiveFilter.maxAge,
      mainCategory: effectiveFilter.mainCategory,
      limit: null,
      offset: null,
    );

    return rows.length;
  }

  Future<List<Voter>> getVotersForExport({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();

    // Build search query for database
    String? searchQuery;
    if (effectiveFilter.searchQuery?.isNotEmpty == true) {
      final effectiveField = effectiveFilter.searchField ?? SearchField.name;
      final effectiveMatchMode =
          effectiveFilter.searchMatchMode ?? SearchMatchMode.startsWith;

      final queryValue = effectiveField == SearchField.voterId
          ? effectiveFilter.searchQuery!
          : effectiveFilter.searchQuery!;
      searchQuery = effectiveMatchMode == SearchMatchMode.startsWith
          ? '$queryValue%'
          : '%$queryValue%';
    }

    final rows = await _dbHelper.getVoters(
      searchQuery: searchQuery,
      startingLetter: effectiveFilter.startingLetter,
      provinceId: await _getProvinceId(effectiveFilter.province),
      districtId: await _getDistrictId(effectiveFilter.district),
      municipalityId: await _getMunicipalityId(effectiveFilter.municipality),
      wardNo: effectiveFilter.wardNo,
      boothCode: effectiveFilter.boothCode,
      gender: effectiveFilter.gender,
      minAge: effectiveFilter.minAge,
      maxAge: effectiveFilter.maxAge,
      mainCategory: effectiveFilter.mainCategory,
      limit: null,
      offset: null,
    );
    return rows.map((row) => Voter.fromMap(row)).toList();
  }

  Future<void> loadAnalyticsData() async {
    state = state.copyWith(isAnalyticsLoading: true);
    try {
      final data = await getAnalyticsData();
      state = state.copyWith(isAnalyticsLoading: false);
    } catch (e) {
      state = state.copyWith(
        isAnalyticsLoading: false,
        analyticsError: e.toString(),
      );
    }
  }

  Future<Voter?> getVoterDetails(int voterId) async {
    final voterMap = await _dbHelper.getVoterById(voterId);
    return voterMap != null ? Voter.fromMap(voterMap) : null;
  }

  void clearAnalyticsCache() {
    state = state.copyWith(analyticsCache: {});
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helper methods for ID resolution
  // ────────────────────────────────────────────────────────────────────────────

  Future<int?> _getProvinceId(String? name) async =>
      name != null ? await _dbHelper.getProvinceIdByName(name) : null;

  Future<int?> _getDistrictId(String? name) async =>
      name != null ? await _dbHelper.getDistrictIdByName(name) : null;

  Future<int?> _getMunicipalityId(String? name) async =>
      name != null ? await _dbHelper.getMunicipalityIdByName(name) : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

final voterProvider = StateNotifierProvider<VoterNotifier, VoterState>(
  (ref) => VoterNotifier(ref.read(searchServiceProvider)),
);
