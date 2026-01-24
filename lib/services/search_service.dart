import '../models/search_models.dart';
import '../models/voter.dart';
import '../helpers/database_helper.dart';
import '../services/transliteration_service.dart';

class SearchService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TransliterationService _transliteration = TransliterationService();

  Future<List<Voter>> performSearch({
    required String query,
    required SearchField field,
    required SearchMatchMode matchMode,
    String? province,
    String? district,
    String? municipality,
    String? wardNo,
    String? boothCode,
    String? gender,
    int? minAge,
    int? maxAge,
    String? mainCategory,
    int limit = 10000,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Build search query with transliteration support
    String searchQuery;
    if (field == SearchField.name) {
      // Try to transliterate English to Nepali
      String transliteratedQuery = await _transliteration.transliterateToNepali(
        query,
      );
      searchQuery = transliteratedQuery.isNotEmpty
          ? transliteratedQuery
          : query;
    } else {
      searchQuery = query;
    }

    // Create search pattern based on match mode
    searchQuery = matchMode == SearchMatchMode.startsWith
        ? '$searchQuery%'
        : '%$searchQuery%';

    // Perform the search
    final rows = await _dbHelper.getVoters(
      searchQuery: searchQuery,
      startingLetter: null, // Not used in search
      provinceId: province != null ? await _getProvinceId(province) : null,
      districtId: district != null ? await _getDistrictId(district) : null,
      municipalityId: municipality != null
          ? await _getMunicipalityId(municipality)
          : null,
      wardNo: wardNo != null ? int.tryParse(wardNo) : null,
      boothCode: boothCode,
      gender: gender,
      minAge: minAge,
      maxAge: maxAge,
      mainCategory: mainCategory,
      limit: limit,
      offset: null,
    );

    return rows.map((row) => Voter.fromMap(row)).toList();
  }

  Future<int?> _getProvinceId(String name) async =>
      await _dbHelper.getProvinceIdByName(name);

  Future<int?> _getDistrictId(String name) async =>
      await _dbHelper.getDistrictIdByName(name);

  Future<int?> _getMunicipalityId(String name) async =>
      await _dbHelper.getMunicipalityIdByName(name);
}
