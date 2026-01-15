import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/database_helper.dart';

// ── Selected Location Providers ───────────────────────────────────────────────
final selectedDistrictProvider = StateProvider<int?>((ref) => null);
final selectedMunicipalityProvider = StateProvider<int?>((ref) => null);
final selectedWardProvider = StateProvider<int?>((ref) => null);
final selectedBoothProvider = StateProvider<int?>((ref) => null);

// ── Koshi Province ID (hardcoded for now, can be queried later)
final koshiProvinceIdProvider = Provider<int>(
  (ref) => 1,
); // Assuming Koshi is province_id = 1

// ── Load Districts under Koshi Province ──────────────────────────────────────
final koshiDistrictsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final dbHelper = DatabaseHelper.instance;
  final provinceId = ref.watch(koshiProvinceIdProvider);

  final db = await dbHelper.database;
  final rows = await db.rawQuery(
    '''
    SELECT id, name
    FROM district
    WHERE province_id = ?
    ORDER BY name
  ''',
    [provinceId],
  );

  return rows;
});

// ── Load Municipalities based on selected District ──────────────────────────
final municipalitiesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int?>((
      ref,
      districtId,
    ) async {
      if (districtId == null) return [];

      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final rows = await db.rawQuery(
        '''
    SELECT id, name, type
    FROM municipality
    WHERE district_id = ?
    ORDER BY name
  ''',
        [districtId],
      );

      return rows;
    });

// ── Load Wards based on selected Municipality ───────────────────────────────
final wardsProvider = FutureProvider.family<List<Map<String, dynamic>>, int?>((
  ref,
  municipalityId,
) async {
  if (municipalityId == null) return [];

  final dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;
  final rows = await db.rawQuery(
    '''
    SELECT id, ward_no
    FROM ward
    WHERE municipality_id = ?
    ORDER BY ward_no
  ''',
    [municipalityId],
  );

  return rows;
});

// ── Load Booths based on selected Ward ──────────────────────────────────────
final boothsProvider = FutureProvider.family<List<Map<String, dynamic>>, int?>((
  ref,
  wardId,
) async {
  if (wardId == null) return [];

  final dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;
  final rows = await db.rawQuery(
    '''
    SELECT id, booth_code, booth_name
    FROM election_booth
    WHERE ward_id = ?
    ORDER BY booth_code
  ''',
    [wardId],
  );

  return rows;
});

// ── Helper Providers for Current Selections (for UI display) ────────────────
final selectedDistrictNameProvider = Provider<String?>((ref) {
  final districtsAsync = ref.watch(koshiDistrictsProvider);
  final selectedId = ref.watch(selectedDistrictProvider);

  if (districtsAsync.value == null || selectedId == null) return null;

  final district = districtsAsync.value!.firstWhere(
    (d) => d['id'] == selectedId,
    orElse: () => {},
  );

  return district['name'] as String?;
});

final selectedMunicipalityNameProvider = Provider<String?>((ref) {
  final municipalitiesAsync = ref.watch(
    municipalitiesProvider(ref.watch(selectedDistrictProvider)),
  );
  final selectedId = ref.watch(selectedMunicipalityProvider);

  if (municipalitiesAsync.value == null || selectedId == null) return null;

  final municipality = municipalitiesAsync.value!.firstWhere(
    (m) => m['id'] == selectedId,
    orElse: () => {},
  );

  return municipality['name'] as String?;
});

final selectedWardNameProvider = Provider<String?>((ref) {
  final wardsAsync = ref.watch(
    wardsProvider(ref.watch(selectedMunicipalityProvider)),
  );
  final selectedId = ref.watch(selectedWardProvider);

  if (wardsAsync.value == null || selectedId == null) return null;

  final ward = wardsAsync.value!.firstWhere(
    (w) => w['id'] == selectedId,
    orElse: () => {},
  );

  return 'वडा ${ward['ward_no']}';
});

final selectedBoothNameProvider = Provider<String?>((ref) {
  final boothsAsync = ref.watch(
    boothsProvider(ref.watch(selectedWardProvider)),
  );
  final selectedId = ref.watch(selectedBoothProvider);

  if (boothsAsync.value == null || selectedId == null) return null;

  final booth = boothsAsync.value!.firstWhere(
    (b) => b['id'] == selectedId,
    orElse: () => {},
  );

  return booth['booth_name'] as String? ?? booth['booth_code'] as String?;
});

// ── Clear All Location Filters ──────────────────────────────────────────────
void clearLocationFilters(WidgetRef ref) {
  ref.read(selectedDistrictProvider.notifier).state = null;
  ref.read(selectedMunicipalityProvider.notifier).state = null;
  ref.read(selectedWardProvider.notifier).state = null;
  ref.read(selectedBoothProvider.notifier).state = null;
}
