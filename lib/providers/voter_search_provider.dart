import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/database_helper.dart';
import '../models/search_models.dart';
import '../models/voter.dart';
import 'location_providers.dart';

// ── Search Params Provider ───────────────────────────────────────────────────
final searchParamsProvider = StateProvider<SearchParams>(
  (ref) => const SearchParams(),
);

// ── Access to DB helper
final dbHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

// ── Main search provider ─────────────────────────────────────────────────────
// Returns real DB results instead of hardcoded list
final voterSearchProvider = FutureProvider.family<List<Voter>, SearchParams>((
  ref,
  params,
) async {
  // Skip query if empty → return empty list (prevents showing all voters)
  final query = params.query.trim();
  if (query.isEmpty) {
    return [];
  }

  final dbHelper = ref.watch(dbHelperProvider);

  try {
    return await dbHelper.searchVotersForProvider(
      query: query,
      field: params.field,
      mode: params.matchMode,
      districtId: ref.watch(selectedDistrictProvider),
      municipalityId: ref.watch(selectedMunicipalityProvider),
      wardId: ref.watch(selectedWardProvider),
      boothId: ref.watch(selectedBoothProvider),
      limit: params.limit,
    );
  } catch (e, stack) {
    // In real app: log error (e.g. Firebase Crashlytics, Sentry)
    print('Search error: $e\n$stack');
    // You can throw or return [] — depending on UX preference
    return [];
  }
});

// ── Optional: derived state providers for UI friendliness ─────────────────────

/// Whether a real search is active (query not empty)
final isSearchingProvider = Provider<bool>((ref) {
  final params = ref.watch(searchParamsProvider);
  return params.query.trim().isNotEmpty;
});

/// Current number of search results (for showing "Found X voters")
final searchResultCountProvider = Provider<int>((ref) {
  final searchAsync = ref.watch(
    voterSearchProvider(ref.watch(searchParamsProvider)),
  );
  return searchAsync.value?.length ?? 0;
});

/// Loading state shortcut (useful for showing spinner only during actual search)
final isSearchLoadingProvider = Provider<bool>((ref) {
  final searchAsync = ref.watch(
    voterSearchProvider(ref.watch(searchParamsProvider)),
  );
  return searchAsync.isLoading && ref.watch(isSearchingProvider);
});
