import 'dart:async';
import 'dart:math' as math;
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
  final globalFilter = ref.watch(filterProvider);
  final voterState = ref.watch(voterProvider);

  // Use the filter from voter state if it has search parameters, otherwise use global filter
  final effectiveFilter =
      voterState.currentFilter?.searchQuery?.isNotEmpty == true
      ? voterState.currentFilter!
      : globalFilter;

  final notifier = ref.read(voterProvider.notifier);
  return notifier.getAnalyticsData(filter: effectiveFilter);
});

// ─────────────────────────────────────────────────────────────────────────────
// Total count provider – depends on current filter
// ─────────────────────────────────────────────────────────────────────────────
final totalVoterCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final globalFilter = ref.watch(filterProvider);
  final voterState = ref.watch(voterProvider);

  // Use the filter from voter state if it has search parameters, otherwise use global filter
  final effectiveFilter =
      voterState.currentFilter?.searchQuery?.isNotEmpty == true
      ? voterState.currentFilter!
      : globalFilter;

  final notifier = ref.read(voterProvider.notifier);
  return notifier.getTotalCount(filter: effectiveFilter);
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
  final List<Voter> voters;
  final List<Voter> allVoters;
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
  final bool isInitialLoad;
  final bool isClientSidePagination;

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

  String _pendingQuery = '';
  Timer? _debounceTimer; // ← added for live search debounce

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

      if (filter.searchQuery?.isNotEmpty == true) {
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

      String? searchQuery;
      if (filter.searchQuery?.isNotEmpty == true) {
        final effectiveField = filter.searchField ?? SearchField.name;
        final effectiveMatchMode =
            filter.searchMatchMode ?? SearchMatchMode.startsWith;

        final queryValue = effectiveField == SearchField.voterId
            ? filter.searchQuery!
            : filter.searchQuery!;

        if (effectiveField == SearchField.name) {
          String transliteratedQuery = await _transliteration
              .transliterateToNepali(queryValue);
          searchQuery = transliteratedQuery.isNotEmpty
              ? transliteratedQuery
              : queryValue;
        } else {
          searchQuery = queryValue;
        }

        searchQuery = effectiveMatchMode == SearchMatchMode.startsWith
            ? '$searchQuery%'
            : '%$searchQuery%';
      }

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

      const int maxClientSideCount = 100000;
      final shouldUseClientSide =
          totalCount <= maxClientSideCount && totalCount > 0;

      if (shouldUseClientSide) {
        final allVoters = totalRows.map((row) => Voter.fromMap(row)).toList();

        final startIndex = (state.currentPage - 1) * state.pageSize;
        final endIndex = state.pageSize == -1
            ? allVoters.length
            : math.min(startIndex + state.pageSize, allVoters.length);

        final pageVoters = allVoters.sublist(startIndex, endIndex);

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
  // Search functionality
  // ────────────────────────────────────────────────────────────────────────────

  void updateQuery(String val) {
    _pendingQuery = val.trim();
  }

  // New: live/debounced search – call this from TextField onChanged
  void searchWithDebounce(String value) {
    _debounceTimer?.cancel();
    updateQuery(value);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (_pendingQuery.isNotEmpty) {
        performSearch(query: _pendingQuery);
      } else {
        loadVoters(); // clear search → show normal filtered list
      }
    });
  }

  Future<void> performSearch({
    String? query,
    SearchField? field,
    SearchMatchMode? matchMode,
  }) async {
    final effectiveQuery = (query ?? _pendingQuery).trim();
    if (effectiveQuery.isEmpty) {
      state = state.copyWith(
        voters: [],
        currentPage: 1,
        totalPages: 1,
        cachedTotalCount: 0,
        isLoading: false,
      );
      return;
    }

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
      var effectiveMatchMode =
          matchMode ?? filter.searchMatchMode ?? SearchMatchMode.startsWith;

      // For testing: temporarily bypass all filters to see if they kill matches
      // TODO: Remove this after debugging
      const bool bypassFiltersForTesting = true;

      // Optional: one-time hardcoded test query — comment it out after testing
      // finalQuery = "गौरव गमाल";

      // Detect if input already contains Devanagari characters
      bool isDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(effectiveQuery);
      debugPrint('Input script: ${isDevanagari ? "Devanagari" : "Romanized"}');

      // Set final query based on script detection
      String finalQuery;
      if (effectiveField == SearchField.name) {
        finalQuery = effectiveQuery.trim();
        debugPrint('Transliteration skipped: already Devanagari');
      } else {
        finalQuery = effectiveQuery;
      }

      // Normalize spaces between Devanagari characters
      finalQuery = finalQuery.replaceAllMapped(
        RegExp(r'([\u0900-\u097F])\s+([\u0900-\u097F])'),
        (match) => '${match.group(1)}${match.group(2)}',
      );
      finalQuery = finalQuery.replaceAll('\u200C', '').replaceAll('\u200D', '');
      debugPrint('Space-normalized query: "$finalQuery"');

      // DEBUG: Print all filter values
      debugPrint(
        'Filters - Province: ${bypassFiltersForTesting ? "BYPASSED" : filter.province}',
      );
      debugPrint(
        'Filters - District: ${bypassFiltersForTesting ? "BYPASSED" : filter.district}',
      );
      debugPrint(
        'Filters - Municipality: ${bypassFiltersForTesting ? "BYPASSED" : filter.municipality}',
      );
      debugPrint(
        'Filters - Ward: ${bypassFiltersForTesting ? "BYPASSED" : filter.wardNo}',
      );
      debugPrint(
        'Filters - Booth: ${bypassFiltersForTesting ? "BYPASSED" : filter.boothCode}',
      );
      debugPrint(
        'Filters - Gender: ${bypassFiltersForTesting ? "BYPASSED" : filter.gender}',
      );
      debugPrint(
        'Filters - Age: ${bypassFiltersForTesting ? "BYPASSED" : "${filter.minAge}-${filter.maxAge}"}',
      );
      debugPrint(
        'Filters - Category: ${bypassFiltersForTesting ? "BYPASSED" : filter.mainCategory}',
      );

      final searchResults = await _searchService.performSearch(
        query: finalQuery, // Pass single query
        field: effectiveField,
        matchMode: effectiveMatchMode,
        // Temporarily bypass all filters for testing
        province: bypassFiltersForTesting ? null : filter.province,
        district: bypassFiltersForTesting ? null : filter.district,
        municipality: bypassFiltersForTesting ? null : filter.municipality,
        wardNo: bypassFiltersForTesting ? null : filter.wardNo?.toString(),
        boothCode: bypassFiltersForTesting ? null : filter.boothCode,
        gender: bypassFiltersForTesting ? null : filter.gender,
        minAge: bypassFiltersForTesting ? null : filter.minAge,
        maxAge: bypassFiltersForTesting ? null : filter.maxAge,
        mainCategory: bypassFiltersForTesting ? null : filter.mainCategory,
        limit: 10000,
      );

      // DEBUG: Print results count
      debugPrint('Results returned: ${searchResults.length}');
      if (searchResults.isEmpty) {
        debugPrint('ZERO RESULTS — possible causes:');
        debugPrint(
          '  - Wrong column name in DB query (check v.name_np vs actual column)',
        );
        debugPrint(
          '  - LIKE pattern not matching (case sensitivity, collation)',
        );
        debugPrint('  - No data in database');
        debugPrint('  - Transliteration producing wrong text');
        debugPrint(
          '  - Field mapping issue (SearchField.name -> "name" vs expected "voterId")',
        );
      } else {
        debugPrint('SUCCESS: Found ${searchResults.length} results');
        // Show first result for verification
        if (searchResults.isNotEmpty) {
          final first = searchResults.first;
          debugPrint(
            'First result: ${first.nameNepali} (ID: ${first.voterNo ?? first.voterId})',
          );
        }
      }

      final totalCount = searchResults.length;
      final totalPages = state.pageSize == -1
          ? 1
          : (totalCount / state.pageSize).ceil();

      final startIndex = 0;
      final endIndex = math.min(
        state.pageSize == -1 ? totalCount : state.pageSize,
        totalCount,
      ); // ← guard

      final pageVoters = searchResults.sublist(startIndex, endIndex);

      final updatedFilter = (state.currentFilter ?? const FilterState())
          .copyWith(
            searchQuery: effectiveQuery,
            searchField: effectiveField,
            searchMatchMode: effectiveMatchMode,
          );

      state = state.copyWith(
        voters: pageVoters,
        allVoters: searchResults,
        totalPages: totalPages,
        cachedTotalCount: totalCount,
        currentFilter: updatedFilter,
        isLoading: false,
        isInitialLoad: true,
        isClientSidePagination: true,
      );

      debugPrint(
        'Search completed: Found ${searchResults.length} voters (showing ${pageVoters.length} on page ${state.currentPage}/${totalPages})',
      );
    } catch (e, stack) {
      debugPrint('Search error: $e\n$stack');
      state = state.copyWith(isLoading: false, loadingError: e.toString());
    }
  }

  List<String> _generateSearchVariants(String query) {
    final variants = <String>[];

    // Full normalized
    final normalized = normalizeForSearch(query);
    variants.add(normalized);

    // Normalized without spaces
    final noSpaces = normalized.replaceAll(' ', '');
    if (noSpaces != normalized) {
      variants.add(noSpaces);
    }

    // First half of normalized (if long enough)
    if (normalized.length > 3) {
      final halfLength = (normalized.length / 2).ceil();
      final firstHalf = normalized.substring(0, halfLength);
      variants.add(firstHalf);
    }

    // Last half of normalized (if long enough)
    if (normalized.length > 3) {
      final halfLength = (normalized.length / 2).floor();
      final lastHalf = normalized.substring(normalized.length - halfLength);
      variants.add(lastHalf);
    }

    // First 4 chars (prefix) - always include for robustness
    if (query.length >= 3) {
      final prefix = normalizeForSearch(
        query.substring(0, query.length > 4 ? 4 : query.length),
      );
      if (!variants.contains(prefix)) {
        variants.add(prefix);
      }
    }

    // For very short queries (<3 chars), only use prefix variant to avoid too many results
    if (query.length < 3) {
      return variants.where((v) => v.length <= 4).toList();
    }

    // Limit to max 5 variants for performance
    return variants.take(5).toList();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // The rest remains completely unchanged
  // ────────────────────────────────────────────────────────────────────────────

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

  Future<void> applyFiltersAndReload(FilterState filter) async {
    FilterState effectiveFilter = filter;

    if (filter.selectedProvinces?.isNotEmpty == true ||
        filter.selectedDistricts?.isNotEmpty == true ||
        filter.selectedMunicipalities?.isNotEmpty == true ||
        filter.selectedWards?.isNotEmpty == true ||
        filter.selectedBooths?.isNotEmpty == true) {
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

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages || page == state.currentPage)
      return;

    if (state.isClientSidePagination && state.allVoters.isNotEmpty) {
      final startIndex = (page - 1) * state.pageSize;
      final endIndex = math.min(
        startIndex + state.pageSize,
        state.allVoters.length,
      ); // ← guard
      final pageVoters = state.allVoters.sublist(startIndex, endIndex);
      state = state.copyWith(currentPage: page, voters: pageVoters);
    } else {
      state = state.copyWith(currentPage: page);
      loadVoters();
    }
  }

  void nextPage() {
    if (state.canGoNext) goToPage(state.currentPage + 1);
  }

  void previousPage() {
    if (state.canGoPrevious) goToPage(state.currentPage - 1);
  }

  Future<void> setPageSize(int size) async {
    if (size == state.pageSize) return;

    if (state.isClientSidePagination && state.allVoters.isNotEmpty) {
      final totalCount = state.allVoters.length;
      final totalPages = size == -1 ? 1 : (totalCount / size).ceil();
      final startIndex = 0;
      final endIndex = math.min(
        size == -1 ? totalCount : size,
        totalCount,
      ); // ← guard
      final pageVoters = state.allVoters.sublist(startIndex, endIndex);

      state = state.copyWith(
        pageSize: size,
        currentPage: 1,
        totalPages: totalPages,
        voters: pageVoters,
      );
    } else {
      state = state.copyWith(pageSize: size, currentPage: 1);
      await loadVoters();
    }
  }

  Future<Map<String, dynamic>> getAnalyticsData({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();

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
    );

    return data;
  }

  Future<Map<String, dynamic>> getAnalyticsDataFromVoters(
    List<Voter> voters,
  ) async {
    final totalVoters = voters.length;

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

    final provinceGroups = <String, int>{};
    for (final voter in voters) {
      final province = voter.province ?? 'Unknown';
      provinceGroups[province] = (provinceGroups[province] ?? 0) + 1;
    }

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

    return rows.length;
  }

  Future<List<Voter>> getVotersForExport({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();

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
