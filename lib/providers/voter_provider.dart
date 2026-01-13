import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/voter.dart';
import '../database_helper.dart';
import '../services/transliteration_service.dart';
import '../providers/filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Reactive analytics provider – recomputes when filter changes
final analyticsDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  // Watch filterProvider → rebuilds on any filter change
  ref.watch(filterProvider);

  // Optional: more precise dependency (only when filter reference changes)
  ref.watch(voterProvider.select((p) => p.currentFilter));

  final voterNotifier = ref.read(voterProvider.notifier);
  return voterNotifier.getAnalyticsData();
});

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
  final Map<String, dynamic>? analyticsData;
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
    this.analyticsData,
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
    Map<String, dynamic>? analyticsData,
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
      analyticsData: analyticsData ?? this.analyticsData,
      isAnalyticsLoading: isAnalyticsLoading ?? this.isAnalyticsLoading,
      analyticsError: analyticsError ?? this.analyticsError,
      loadingError: loadingError ?? this.loadingError,
    );
  }

  bool get canGoPrevious => currentPage > 1;
  bool get canGoNext => currentPage < totalPages;
}

class VoterNotifier extends StateNotifier<VoterState> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TransliterationService _transliterationService =
      TransliterationService();

  static const List<String> _groupByOptions = [
    'province',
    'district',
    'municipality',
    'ward',
    'booth',
  ];

  VoterNotifier() : super(VoterState());

  Future<List<Voter>> getVotersForExport(int start, int end) async {
    final limit = end - start + 1;
    final offset = start - 1;

    final rawData = await _dbHelper.getVoters(
      searchQuery: state.currentFilter?.searchQuery,
      transliteratedQuery: await _getTransliteratedQuery(),
      startingLetter: state.currentFilter?.startingLetter,
      boothCode: state.currentFilter?.boothCode,
      wardNo: state.currentFilter?.wardNo,
      municipalityId: await _getMunicipalityId(
        state.currentFilter?.municipality,
      ),
      districtId: await _getDistrictId(state.currentFilter?.district),
      provinceId: await _getProvinceId(state.currentFilter?.province),
      gender: state.currentFilter?.gender,
      minAge: state.currentFilter?.ageRange?.start.round(),
      maxAge: state.currentFilter?.ageRange?.end.round(),
      limit: limit,
      offset: offset,
    );

    return rawData.map((map) => Voter.fromMap(map)).toList();
  }

  Future<String?> _getTransliteratedQuery() async {
    if (state.currentFilter?.searchQuery?.isNotEmpty != true) return null;
    try {
      return await _transliterationService.transliterateToNepali(
        state.currentFilter!.searchQuery!,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getVoterDetails(int voterId) async {
    try {
      final details = await _dbHelper.getVoterDetails(voterId);
      return details;
    } catch (e) {
      debugPrint('Error fetching voter details: $e');
      return {};
    }
  }

  Future<int> getTotalCount() async {
    if (state.cachedTotalCount != null) return state.cachedTotalCount!;

    final count = await _dbHelper.getVoterCount(
      searchQuery: state.currentFilter?.searchQuery,
      startingLetter: state.currentFilter?.startingLetter,
      boothCode: state.currentFilter?.boothCode,
      wardNo: state.currentFilter?.wardNo,
      municipalityId: await _getMunicipalityId(
        state.currentFilter?.municipality,
      ),
      districtId: await _getDistrictId(state.currentFilter?.district),
      provinceId: await _getProvinceId(state.currentFilter?.province),
      gender: state.currentFilter?.gender,
      minAge: state.currentFilter?.ageRange?.start.round(),
      maxAge: state.currentFilter?.ageRange?.end.round(),
    );

    state = state.copyWith(cachedTotalCount: count);
    return count;
  }

  Future<int?> _getProvinceId(String? name) async {
    return name != null ? await _dbHelper.getProvinceIdByName(name) : null;
  }

  Future<int?> _getDistrictId(String? name) async {
    return name != null ? await _dbHelper.getDistrictIdByName(name) : null;
  }

  Future<int?> _getMunicipalityId(String? name) async {
    return name != null ? await _dbHelper.getMunicipalityIdByName(name) : null;
  }

  Future<void> loadVoters() async {
    debugPrint('loadVoters: Starting to load voters');
    state = state.copyWith(isLoading: true, loadingError: null);

    try {
      await _performLoadVoters().timeout(const Duration(seconds: 30));
    } on TimeoutException catch (error) {
      debugPrint('loadVoters: Timeout error: $error');
      state = state.copyWith(
        isLoading: false,
        loadingError:
            'Loading timed out after 30 seconds. Please check your database connection.',
      );
    } catch (error) {
      debugPrint('loadVoters: Error loading voters: $error');
      state = state.copyWith(isLoading: false, loadingError: error.toString());
    }
  }

  Future<void> _performLoadVoters() async {
    debugPrint('loadVoters: Starting transliteration if needed');
    String? transliterated;
    if (state.currentFilter?.searchQuery?.isNotEmpty == true) {
      transliterated = await _transliterationService.transliterateToNepali(
        state.currentFilter!.searchQuery!,
      );
      debugPrint('loadVoters: Transliterated query: $transliterated');
    }

    debugPrint('loadVoters: Getting total count');
    final total = await getTotalCount();
    debugPrint('loadVoters: Total count: $total');

    final totalPages = state.pageSize == -1
        ? 1
        : (total / state.pageSize).ceil();
    debugPrint('loadVoters: Total pages: $totalPages');

    debugPrint('loadVoters: Fetching voters from database');
    final newItems = await _dbHelper.getVoters(
      searchQuery: state.currentFilter?.searchQuery,
      transliteratedQuery: transliterated,
      startingLetter: state.currentFilter?.startingLetter,
      boothCode: state.currentFilter?.boothCode,
      wardNo: state.currentFilter?.wardNo,
      municipalityId: await _getMunicipalityId(
        state.currentFilter?.municipality,
      ),
      districtId: await _getDistrictId(state.currentFilter?.district),
      provinceId: await _getProvinceId(state.currentFilter?.province),
      gender: state.currentFilter?.gender,
      minAge: state.currentFilter?.ageRange?.start.round(),
      maxAge: state.currentFilter?.ageRange?.end.round(),
      limit: state.pageSize == -1 ? null : state.pageSize,
      offset: state.pageSize == -1
          ? null
          : (state.currentPage - 1) * state.pageSize,
    );
    debugPrint('loadVoters: Fetched ${newItems.length} voters');

    state = state.copyWith(
      voters: newItems.map((e) => Voter.fromMap(e)).toList(),
      totalPages: totalPages,
      cachedTotalCount: total,
      isLoading: false,
    );
    debugPrint('loadVoters: Successfully loaded voters');
  }

  Future<void> applyFiltersAndReload(FilterState filter) async {
    state = state.copyWith(
      currentFilter: filter,
      currentPage: 1,
      cachedTotalCount: null,
    );
    clearAnalyticsData();
    await loadVoters();
  }

  void clearFilters() {
    state = state.copyWith(
      currentFilter: FilterState(),
      currentPage: 1,
      cachedTotalCount: null,
    );
    clearAnalyticsData();
    loadVoters();
  }

  void setPageSize(int size) {
    if (state.pageSize == size) return;
    state = state.copyWith(
      pageSize: size,
      currentPage: 1,
      cachedTotalCount: null,
    );
    loadVoters();
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages || page == state.currentPage)
      return;
    state = state.copyWith(currentPage: page);
    loadVoters();
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadVoters();
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      loadVoters();
    }
  }

  Future<Map<String, dynamic>> getAnalyticsData() async {
    final cacheKey = '${state.currentFilter}#${state.groupBy}';
    if (state.analyticsCache.containsKey(cacheKey)) {
      return state.analyticsCache[cacheKey]!;
    }

    final data = await _dbHelper.getAnalyticsData(
      searchQuery: state.currentFilter?.searchQuery,
      startingLetter: state.currentFilter?.startingLetter,
      boothCode: state.currentFilter?.boothCode,
      wardNo: state.currentFilter?.wardNo,
      municipalityId: await _getMunicipalityId(
        state.currentFilter?.municipality,
      ),
      districtId: await _getDistrictId(state.currentFilter?.district),
      provinceId: await _getProvinceId(state.currentFilter?.province),
      gender: state.currentFilter?.gender,
      minAge: state.currentFilter?.ageRange?.start.round(),
      maxAge: state.currentFilter?.ageRange?.end.round(),
      groupBy: state.groupBy,
    );

    state = state.copyWith(
      analyticsCache: {...state.analyticsCache, cacheKey: data},
    );
    return data;
  }

  void setGroupBy(String value) {
    if (!_groupByOptions.contains(value) || state.groupBy == value) return;
    state = state.copyWith(groupBy: value, analyticsCache: {});
  }

  Future<void> loadAnalyticsData() async {
    if (state.analyticsData != null) return; // Already loaded

    state = state.copyWith(isAnalyticsLoading: true, analyticsError: null);

    try {
      final data = await getAnalyticsData();
      state = state.copyWith(analyticsData: data, isAnalyticsLoading: false);
    } catch (error) {
      state = state.copyWith(
        analyticsError: error.toString(),
        isAnalyticsLoading: false,
      );
    }
  }

  void clearAnalyticsData() {
    state = state.copyWith(
      analyticsData: null,
      analyticsError: null,
      isAnalyticsLoading: false,
    );
  }

  void refresh() {
    state = state.copyWith(cachedTotalCount: null);
    loadVoters();
    state = state.copyWith(analyticsCache: {});
    clearAnalyticsData();
  }
}

final voterProvider = StateNotifierProvider<VoterNotifier, VoterState>(
  (ref) => VoterNotifier(),
);

final totalVoterCountProvider = FutureProvider.autoDispose<int>((ref) async {
  // Watch the current filter from filterProvider
  final currentFilter = ref.watch(filterProvider);

  // Watch the voter provider's current filter to trigger recomputation when it changes
  ref.watch(voterProvider.select((state) => state.currentFilter));

  // Now safely call the method
  final voterNotifier = ref.read(voterProvider.notifier);
  return voterNotifier.getTotalCount();
});
