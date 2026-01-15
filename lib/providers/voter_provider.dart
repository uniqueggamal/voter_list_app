import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voter.dart';
import '../helpers/database_helper.dart';
import '../services/transliteration_service.dart';
import '../providers/filter_provider.dart';
import '../helpers/text_helper.dart';
import '../models/search_params.dart';
import '../providers/voter_search_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Analytics provider – recomputes when filter changes
// ─────────────────────────────────────────────────────────────────────────────

final analyticsDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final filter = ref.watch(filterProvider);
  final notifier = ref.read(voterProvider.notifier);
  return notifier.getAnalyticsData(filter: filter);
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
// Main Voter State & Notifier
// ─────────────────────────────────────────────────────────────────────────────

class VoterState {
  final List<Voter> voters;
  final bool isLoading;
  final int pageSize;
  final int currentPage;
  final int totalPages;
  final FilterState? currentFilter;
  final String groupBy;
  final Map<String, Map<String, dynamic>> analyticsCache;
  final int? cachedTotalCount;
  final bool isAnalyticsLoading;
  final String? analyticsError;
  final String? loadingError;

  VoterState({
    this.voters = const [],
    this.isLoading = false,
    this.pageSize = 100,
    this.currentPage = 1,
    this.totalPages = 1,
    this.currentFilter,
    this.groupBy = 'ward',
    this.analyticsCache = const {},
    this.cachedTotalCount,
    this.isAnalyticsLoading = false,
    this.analyticsError,
    this.loadingError,
  });

  VoterState copyWith({
    List<Voter>? voters,
    bool? isLoading,
    int? pageSize,
    int? currentPage,
    int? totalPages,
    FilterState? currentFilter,
    String? groupBy,
    Map<String, Map<String, dynamic>>? analyticsCache,
    int? cachedTotalCount,
    bool? isAnalyticsLoading,
    String? analyticsError,
    String? loadingError,
  }) {
    return VoterState(
      voters: voters ?? this.voters,
      isLoading: isLoading ?? this.isLoading,
      pageSize: pageSize ?? this.pageSize,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentFilter: currentFilter ?? this.currentFilter,
      groupBy: groupBy ?? this.groupBy,
      analyticsCache: analyticsCache ?? this.analyticsCache,
      cachedTotalCount: cachedTotalCount ?? this.cachedTotalCount,
      isAnalyticsLoading: isAnalyticsLoading ?? this.isAnalyticsLoading,
      analyticsError: analyticsError ?? this.analyticsError,
      loadingError: loadingError ?? this.loadingError,
    );
  }

  bool get canGoPrevious => currentPage > 1;
  bool get canGoNext => currentPage < totalPages;
}

class VoterNotifier extends StateNotifier<VoterState> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TransliterationService _transliteration = TransliterationService();

  static const List<String> _groupByOptions = [
    'province',
    'district',
    'municipality',
    'ward',
    'booth',
  ];

  VoterNotifier() : super(VoterState());

  // ────────────────────────────────────────────────────────────────────────────
  // Core loading logic
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> loadVoters({
    SearchField? field,
    SearchMatchMode? matchMode,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, loadingError: null);
    debugPrint('VoterNotifier: Loading voters (page ${state.currentPage})');

    try {
      final filter = state.currentFilter ?? const FilterState();

      // Transliterate search query if needed
      String? transliteratedQuery;
      if (filter.searchQuery?.isNotEmpty == true) {
        transliteratedQuery = await _transliteration.transliterateToNepali(
          filter.searchQuery!,
        );
        debugPrint('Transliterated query: $transliteratedQuery');
      }

      // Fetch all voters with other filters (no search)
      final rows = await _dbHelper.getVoters(
        searchQuery: null,
        transliteratedQuery: null,
        startingLetter: filter.startingLetter,
        field: null,
        matchMode: null,
        provinceId: await _getProvinceId(filter.province),
        districtId: await _getDistrictId(filter.district),
        municipalityId: await _getMunicipalityId(filter.municipality),
        wardNo: filter.wardNo,
        boothCode: filter.boothCode,
        gender: filter.gender,
        minAge: filter.minAge,
        maxAge: filter.maxAge,
        limit: null,
        offset: null,
      );

      List<Voter> allVoters = rows.map((row) => Voter.fromMap(row)).toList();

      // Apply search filtering in memory if query exists
      List<Voter> filteredVoters = allVoters;
      if (filter.searchQuery?.isNotEmpty == true) {
        final queryNorm = normalizeNepali(filter.searchQuery);
        final effectiveField = field ?? filter.searchField ?? SearchField.name;
        final effectiveMatchMode =
            matchMode ?? filter.searchMatchMode ?? SearchMatchMode.startsWith;

        filteredVoters = allVoters.where((v) {
          final value = effectiveField == SearchField.voterId
              ? v.voterId
              : v.nameNepali;
          final valueNorm = normalizeNepali(value);
          final matches = effectiveMatchMode == SearchMatchMode.startsWith
              ? valueNorm.startsWith(queryNorm)
              : valueNorm.contains(queryNorm);

          if (kDebugMode) {
            debugPrint(
              'Query: "$queryNorm", Value: "$valueNorm", Matches: $matches',
            );
          }

          return matches;
        }).toList();
      }

      final totalCount = filteredVoters.length;
      final totalPages = state.pageSize == -1
          ? 1
          : (totalCount / state.pageSize).ceil();

      // Paginate the filtered list
      final startIndex = state.pageSize == -1
          ? 0
          : (state.currentPage - 1) * state.pageSize;
      final endIndex = state.pageSize == -1
          ? filteredVoters.length
          : (startIndex + state.pageSize).clamp(0, filteredVoters.length);
      final newVoters = filteredVoters.sublist(startIndex, endIndex);

      state = state.copyWith(
        voters: newVoters,
        totalPages: totalPages,
        cachedTotalCount: totalCount,
        isLoading: false,
      );

      debugPrint(
        'Loaded ${newVoters.length} voters | Total: $totalCount | Pages: $totalPages',
      );
    } catch (e, stack) {
      debugPrint('VoterNotifier load error: $e\n$stack');
      state = state.copyWith(isLoading: false, loadingError: e.toString());
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Filter & reload
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> applyFiltersAndReload(FilterState filter) async {
    state = state.copyWith(
      currentFilter: filter,
      currentPage: 1,
      cachedTotalCount: null,
    );
    clearAnalyticsCache();
    await loadVoters();
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
  // Pagination
  // ────────────────────────────────────────────────────────────────────────────

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages || page == state.currentPage)
      return;
    state = state.copyWith(currentPage: page);
    loadVoters();
  }

  void nextPage() {
    if (state.canGoNext) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadVoters();
    }
  }

  void previousPage() {
    if (state.canGoPrevious) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      loadVoters();
    }
  }

  void setPageSize(int size) {
    if (size == state.pageSize) return;
    state = state.copyWith(
      pageSize: size,
      currentPage: 1,
      cachedTotalCount: null,
    );
    loadVoters();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Analytics
  // ────────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalyticsData({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();
    final cacheKey = effectiveFilter.toString() + state.groupBy;

    if (state.analyticsCache.containsKey(cacheKey)) {
      return state.analyticsCache[cacheKey]!;
    }

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
      groupBy: state.groupBy,
    );

    state = state.copyWith(
      analyticsCache: {...state.analyticsCache, cacheKey: data},
    );

    return data;
  }

  Future<int> getTotalCount({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();

    // Fetch all voters with other filters
    final rows = await _dbHelper.getVoters(
      searchQuery: null,
      transliteratedQuery: null,
      startingLetter: effectiveFilter.startingLetter,
      field: null,
      matchMode: null,
      provinceId: await _getProvinceId(effectiveFilter.province),
      districtId: await _getDistrictId(effectiveFilter.district),
      municipalityId: await _getMunicipalityId(effectiveFilter.municipality),
      wardNo: effectiveFilter.wardNo,
      boothCode: effectiveFilter.boothCode,
      gender: effectiveFilter.gender,
      minAge: effectiveFilter.minAge,
      maxAge: effectiveFilter.maxAge,
      limit: null,
      offset: null,
    );

    List<Voter> allVoters = rows.map((row) => Voter.fromMap(row)).toList();

    // Apply search filtering in memory if query exists
    if (effectiveFilter.searchQuery?.isNotEmpty == true) {
      final queryNorm = normalizeNepali(effectiveFilter.searchQuery);
      final effectiveField = effectiveFilter.searchField ?? SearchField.name;
      final effectiveMatchMode =
          effectiveFilter.searchMatchMode ?? SearchMatchMode.startsWith;

      allVoters = allVoters.where((v) {
        final value = effectiveField == SearchField.voterId
            ? v.voterId
            : v.nameNepali;
        final valueNorm = normalizeNepali(value);
        return effectiveMatchMode == SearchMatchMode.startsWith
            ? valueNorm.startsWith(queryNorm)
            : valueNorm.contains(queryNorm);
      }).toList();
    }

    return allVoters.length;
  }

  Future<List<Voter>> getVotersForExport({FilterState? filter}) async {
    final effectiveFilter =
        filter ?? state.currentFilter ?? const FilterState();
    final rows = await _dbHelper.getVoters(
      searchQuery: effectiveFilter.searchQuery,
      transliteratedQuery: null,
      startingLetter: effectiveFilter.startingLetter,
      provinceId: await _getProvinceId(effectiveFilter.province),
      districtId: await _getDistrictId(effectiveFilter.district),
      municipalityId: await _getMunicipalityId(effectiveFilter.municipality),
      wardNo: effectiveFilter.wardNo,
      boothCode: effectiveFilter.boothCode,
      gender: effectiveFilter.gender,
      minAge: effectiveFilter.minAge,
      maxAge: effectiveFilter.maxAge,
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

final voterProvider = StateNotifierProvider<VoterNotifier, VoterState>(
  (ref) => VoterNotifier(),
);
