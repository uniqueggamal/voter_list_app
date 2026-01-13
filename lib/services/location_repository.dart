import 'dart:convert';
import 'package:flutter/services.dart';

class LocationRepository {
  final Map<String, dynamic> _data;

  LocationRepository(Map<String, dynamic> data)
    : _data = _trimKeys(data) as Map<String, dynamic>;

  static String _normalize(String key) => key.trim();

  static dynamic _trimKeys(dynamic data) {
    if (data is Map) {
      final newMap = <String, dynamic>{};
      for (final entry in data.entries) {
        final key = entry.key is String
            ? (entry.key as String).trim()
            : entry.key;
        final value = _trimKeys(entry.value);
        newMap[key] = value;
      }
      return newMap;
    } else if (data is List) {
      return data.map(_trimKeys).toList();
    } else {
      return data;
    }
  }

  static Future<LocationRepository> loadFromAsset(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final decoded = json.decode(jsonString);
    return LocationRepository(decoded is Map<String, dynamic> ? decoded : {});
  }

  List<String> getProvinces() {
    return _data.keys.whereType<String>().toList();
  }

  List<String> getDistricts({String? province}) {
    final Set<String> result = {};

    if (province == null) {
      // All districts in Nepal
      for (final provinceData in _data.values) {
        if (provinceData is! Map) continue;
        final districts = provinceData['districts'] as Map?;
        if (districts != null) {
          result.addAll(districts.keys.whereType<String>());
        }
      }
    } else {
      final provinceData = _data[province];
      if (provinceData is Map) {
        final districts = provinceData['districts'] as Map?;
        if (districts != null) {
          result.addAll(districts.keys.whereType<String>());
        }
      }
    }

    return result.toList()..sort();
  }

  List<String> getMunicipalities({String? province, String? district}) {
    final Set<String> result = {};

    if (province == null && district == null) {
      // All municipalities in Nepal
      for (final provinceData in _data.values) {
        if (provinceData is! Map) continue;
        final districtsMap = provinceData['districts'] as Map?;
        if (districtsMap == null) continue;

        for (final districtData in districtsMap.values) {
          if (districtData is! Map) continue;
          final municipalities = districtData['municipalities'] as Map?;
          if (municipalities != null) {
            result.addAll(municipalities.keys.whereType<String>());
          }
        }
      }
    } else if (province != null && district == null) {
      // All municipalities in selected province
      final provinceData = _data[province];
      if (provinceData is Map) {
        final districtsMap = provinceData['districts'] as Map?;
        if (districtsMap != null) {
          for (final districtData in districtsMap.values) {
            if (districtData is! Map) continue;
            final municipalities = districtData['municipalities'] as Map?;
            if (municipalities != null) {
              result.addAll(municipalities.keys.whereType<String>());
            }
          }
        }
      }
    } else if (province != null && district != null) {
      // Specific district
      final provinceData = _data[province];
      if (provinceData is! Map) return [];
      final districtData = (provinceData['districts'] as Map?)?[district];
      if (districtData is! Map) return [];
      final municipalities = districtData['municipalities'] as Map?;
      if (municipalities != null) {
        result.addAll(municipalities.keys.whereType<String>());
      }
    }

    return result.toList()..sort();
  }

  List<Map<String, dynamic>> getWards({
    String? province,
    String? district,
    String? municipality,
  }) {
    final List<Map<String, dynamic>> result = [];

    // Helper to collect wards from one municipality map
    void collectWardsFromMunicipality(Map? munData) {
      if (munData == null) return;
      final wardsMap = munData['wards'] as Map?;
      if (wardsMap != null) {
        for (final wardValue in wardsMap.values) {
          if (wardValue is Map<String, dynamic>) {
            result.add(wardValue);
          }
        }
      }
    }

    if (province == null && district == null && municipality == null) {
      // All wards in Nepal
      for (final provinceData in _data.values) {
        if (provinceData is! Map) continue;
        final districtsMap = provinceData['districts'] as Map?;
        if (districtsMap == null) continue;
        for (final districtData in districtsMap.values) {
          if (districtData is! Map) continue;
          final muns = districtData['municipalities'] as Map?;
          if (muns != null) {
            for (final munData in muns.values) {
              collectWardsFromMunicipality(munData);
            }
          }
        }
      }
    } else if (province != null && district == null && municipality == null) {
      // All wards in selected province
      final provinceData = _data[province];
      if (provinceData is Map) {
        final districtsMap = provinceData['districts'] as Map?;
        if (districtsMap != null) {
          for (final districtData in districtsMap.values) {
            if (districtData is! Map) continue;
            final muns = districtData['municipalities'] as Map?;
            if (muns != null) {
              for (final munData in muns.values) {
                collectWardsFromMunicipality(munData);
              }
            }
          }
        }
      }
    } else if (province != null && district != null && municipality == null) {
      // All wards in selected district
      final provinceData = _data[province];
      if (provinceData is! Map) return [];
      final districtData = (provinceData['districts'] as Map?)?[district];
      if (districtData is! Map) return [];
      final muns = districtData['municipalities'] as Map?;
      if (muns != null) {
        for (final munData in muns.values) {
          collectWardsFromMunicipality(munData);
        }
      }
    } else if (province != null && district != null && municipality != null) {
      // Specific municipality
      final municipalityData =
          (((_data[province] as Map?)?['districts'] as Map?)?[district]
                  as Map?)?['municipalities']
              as Map?;

      if (municipalityData == null) return [];

      final normalized = _normalize(municipality);
      String? actualKey;
      for (final key in municipalityData.keys.whereType<String>()) {
        if (_normalize(key) == normalized) {
          actualKey = key;
          break;
        }
      }

      if (actualKey == null) return [];

      final wardsMap = (municipalityData[actualKey] as Map?)?['wards'] as Map?;
      if (wardsMap != null) {
        result.addAll(wardsMap.values.whereType<Map<String, dynamic>>());
      }
    }

    // Sort by ward_no if available
    result.sort((a, b) {
      final noA = a['ward_no'] as int? ?? 0;
      final noB = b['ward_no'] as int? ?? 0;
      return noA.compareTo(noB);
    });

    return result;
  }

  List<Map<String, dynamic>> getBooths({
    String? province,
    String? district,
    String? municipality,
    int? wardNo,
  }) {
    final List<Map<String, dynamic>> result = [];

    void collectBoothsFromWard(Map? wardData) {
      if (wardData == null) return;
      final booths = wardData['booths'] as List?;
      if (booths != null) {
        result.addAll(booths.whereType<Map<String, dynamic>>());
      }
    }

    if (province == null &&
        district == null &&
        municipality == null &&
        wardNo == null) {
      // All booths in Nepal
      for (final provinceData in _data.values) {
        if (provinceData is! Map) continue;
        final districtsMap = provinceData['districts'] as Map?;
        if (districtsMap == null) continue;
        for (final districtData in districtsMap.values) {
          if (districtData is! Map) continue;
          final muns = districtData['municipalities'] as Map?;
          if (muns == null) continue;
          for (final munData in muns.values) {
            if (munData is! Map) continue;
            final wards = munData['wards'] as Map?;
            if (wards != null) {
              for (final wardData in wards.values) {
                collectBoothsFromWard(wardData);
              }
            }
          }
        }
      }
    } else if (province != null &&
        district == null &&
        municipality == null &&
        wardNo == null) {
      // All booths in selected province
      final provinceData = _data[province];
      if (provinceData is Map) {
        final districtsMap = provinceData['districts'] as Map?;
        if (districtsMap != null) {
          for (final districtData in districtsMap.values) {
            if (districtData is! Map) continue;
            final muns = districtData['municipalities'] as Map?;
            if (muns == null) continue;
            for (final munData in muns.values) {
              if (munData is! Map) continue;
              final wards = munData['wards'] as Map?;
              if (wards != null) {
                for (final wardData in wards.values) {
                  collectBoothsFromWard(wardData);
                }
              }
            }
          }
        }
      }
    } else if (province != null &&
        district != null &&
        municipality == null &&
        wardNo == null) {
      // All booths in selected district
      final provinceData = _data[province];
      if (provinceData is! Map) return [];
      final districtData = (provinceData['districts'] as Map?)?[district];
      if (districtData is! Map) return [];
      final muns = districtData['municipalities'] as Map?;
      if (muns != null) {
        for (final munData in muns.values) {
          if (munData is! Map) continue;
          final wards = munData['wards'] as Map?;
          if (wards != null) {
            for (final wardData in wards.values) {
              collectBoothsFromWard(wardData);
            }
          }
        }
      }
    } else if (province != null &&
        district != null &&
        municipality != null &&
        wardNo == null) {
      // All booths in selected municipality
      final municipalityData =
          (((_data[province] as Map?)?['districts'] as Map?)?[district]
                  as Map?)?['municipalities']
              as Map?;

      if (municipalityData == null) return [];

      final normalized = _normalize(municipality);
      String? actualKey;
      for (final key in municipalityData.keys.whereType<String>()) {
        if (_normalize(key) == normalized) {
          actualKey = key;
          break;
        }
      }

      if (actualKey == null) return [];

      final wardsMap = (municipalityData[actualKey] as Map?)?['wards'] as Map?;
      if (wardsMap != null) {
        for (final wardData in wardsMap.values) {
          collectBoothsFromWard(wardData);
        }
      }
    } else if (province != null &&
        district != null &&
        municipality != null &&
        wardNo != null) {
      // Specific ward
      final wardsMap =
          ((((_data[province] as Map?)?['districts'] as Map?)?[district]
                      as Map?)?['municipalities']
                  as Map?)?[municipality]?['wards']
              as Map?;

      if (wardsMap != null) {
        for (final wardValue in wardsMap.values) {
          if (wardValue is Map && (wardValue['ward_no'] as int?) == wardNo) {
            final booths = wardValue['booths'] as List?;
            if (booths != null) {
              result.addAll(booths.whereType<Map<String, dynamic>>());
            }
          }
        }
      }
    }

    // Sort booths by booth_code if available
    result.sort((a, b) {
      final codeA = a['booth_code'] as String? ?? '';
      final codeB = b['booth_code'] as String? ?? '';
      return codeA.compareTo(codeB);
    });

    return result;
  }
}
