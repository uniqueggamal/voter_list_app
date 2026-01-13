import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// VoterDataProvider is responsible for loading hierarchical location data
/// (provinces, districts, municipalities, wards, booths) from a pre-generated JSON file.
/// This approach is much faster than querying the database repeatedly.
class VoterDataProvider extends ChangeNotifier {
  // Hierarchical data structure with nested references
  Map<String, Map<String, dynamic>> provincesData = {};

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  VoterDataProvider() {
    loadDataFromJson();
  }

  /// Loads all hierarchical data from a pre-generated JSON file.
  /// This is much faster than querying the database repeatedly.
  Future<void> loadDataFromJson() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load JSON data from assets
      final jsonString = await rootBundle.loadString(
        'assets/location_data.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Convert JSON structure to the expected format
      provincesData.clear();

      for (final provinceEntry in jsonData.entries) {
        final provinceName = provinceEntry.key;
        final provinceData = provinceEntry.value as Map<String, dynamic>;

        provincesData[provinceName] = {
          'data': {'name': provinceName, 'id': provinceData['id']},
          'districts': <String, Map<String, dynamic>>{},
        };

        // Process districts
        final districtsData = provinceData['districts'] as Map<String, dynamic>;
        for (final districtEntry in districtsData.entries) {
          final districtName = districtEntry.key;
          final districtData = districtEntry.value as Map<String, dynamic>;

          provincesData[provinceName]!['districts'][districtName] = {
            'data': {'name': districtName, 'id': districtData['id']},
            'municipalities': <String, Map<String, dynamic>>{},
          };

          // Process municipalities
          final municipalitiesData =
              districtData['municipalities'] as Map<String, dynamic>;
          for (final municipalityEntry in municipalitiesData.entries) {
            final municipalityName = municipalityEntry.key;
            final municipalityData =
                municipalityEntry.value as Map<String, dynamic>;

            provincesData[provinceName]!['districts'][districtName]!['municipalities'][municipalityName] =
                {
                  'data': {
                    'name': municipalityName,
                    'id': municipalityData['id'],
                    'type': municipalityData['type'],
                    'municipality_code': municipalityData['type'],
                  },
                  'wards': <String, Map<String, dynamic>>{},
                };

            // Process wards
            final wardsData = municipalityData['wards'] as Map<String, dynamic>;
            for (final wardEntry in wardsData.entries) {
              final wardKey = wardEntry.key;
              final wardData = wardEntry.value as Map<String, dynamic>;

              provincesData[provinceName]!['districts'][districtName]!['municipalities'][municipalityName]!['wards'][wardKey] =
                  {
                    'data': {
                      'ward_no': wardData['ward_no'],
                      'municipality_code': municipalityData['type'],
                    },
                    'booths': wardData['booths'] as List<Map<String, dynamic>>,
                  };
            }
          }
        }
      }

      debugPrint('Location data loaded successfully from JSON');
    } catch (e) {
      debugPrint('Error loading location data from JSON: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getter for provinces list
  List<String> get provinces => provincesData.keys.toList();

  /// Returns list of districts for a given province, or empty list if not found.
  List<String> getDistrictsForProvince(String? province) {
    if (province == null) return [];
    return provincesData[province]?['districts']?.keys.toList() ?? [];
  }

  /// Returns list of municipalities for a given district, or empty list if not found.
  List<String> getMunicipalitiesForDistrict(String? district) {
    if (district == null) return [];
    // Find the district across all provinces
    for (final provinceData in provincesData.values) {
      if (provinceData['districts'].containsKey(district)) {
        return provinceData['districts'][district]['municipalities'].keys
            .toList();
      }
    }
    return [];
  }

  /// Returns list of wards for a given municipality, or empty list if not found.
  List<Map<String, dynamic>> getWardsForMunicipality(String? municipality) {
    if (municipality == null) return [];
    // Find the municipality across all provinces and districts
    for (final provinceData in provincesData.values) {
      for (final districtData in provinceData['districts'].values) {
        if (districtData['municipalities'].containsKey(municipality)) {
          return districtData['municipalities'][municipality]['wards'].values
              .map((ward) => ward['data'] as Map<String, dynamic>)
              .toList();
        }
      }
    }
    return [];
  }

  /// Returns list of booths for a given municipality and ward, or empty list if not found.
  List<Map<String, dynamic>> getBoothsForWard(
    String? municipality,
    int? wardNo,
  ) {
    if (municipality == null || wardNo == null) return [];
    // Find the ward across all provinces, districts, and municipalities
    for (final provinceData in provincesData.values) {
      for (final districtData in provinceData['districts'].values) {
        if (districtData['municipalities'].containsKey(municipality)) {
          final municipalityData = districtData['municipalities'][municipality];
          final wardKey =
              '${municipalityData['data']['municipality_code']}-$wardNo';
          if (municipalityData['wards'].containsKey(wardKey)) {
            return municipalityData['wards'][wardKey]['booths'];
          }
        }
      }
    }
    return [];
  }

  /// Returns all booths from all provinces, districts, municipalities, and wards.
  List<Map<String, dynamic>> get booths {
    final allBooths = <Map<String, dynamic>>[];
    for (final provinceData in provincesData.values) {
      for (final districtData in provinceData['districts'].values) {
        for (final municipalityData in districtData['municipalities'].values) {
          for (final wardData in municipalityData['wards'].values) {
            allBooths.addAll(wardData['booths'] as List<Map<String, dynamic>>);
          }
        }
      }
    }
    return allBooths;
  }
}
