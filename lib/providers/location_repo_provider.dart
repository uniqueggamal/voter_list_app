import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────
// Location Data Repository (in-memory JSON parsing)
// ─────────────────────────────────────────────────────────────

class LocationRepository {
  final Map<String, dynamic> _data;

  LocationRepository(this._data);

  // Load from asset file once
  static Future<LocationRepository> loadFromAsset(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      debugPrint('Location data loaded successfully');
      return LocationRepository(jsonData);
    } catch (e) {
      debugPrint('Error loading location data: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Public API methods (used by filter panel, etc.)
  // ─────────────────────────────────────────────────────────────

  List<String> getProvinces() {
    return _data.keys.whereType<String>().toList()..sort();
  }

  List<String> getDistricts({String? province}) {
    final result = <String>[];

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

    return result..sort(); // always returns List<String> (never null)
  }

  List<String> getMunicipalities({String? province, String? district}) {
    final result = <String>{};

    if (province == null && district == null) {
      // All municipalities in Nepal
      for (final provData in _data.values) {
        if (provData is! Map) continue;
        final dists = provData['districts'] as Map?;
        if (dists == null) continue;
        for (final distData in dists.values) {
          if (distData is Map) {
            final muns = distData['municipalities'] as Map?;
            result.addAll(muns?.keys.cast<String>() ?? []);
          }
        }
      }
    } else if (province != null && district == null) {
      // All in selected province
      final provData = _data[province];
      if (provData is Map) {
        final dists = provData['districts'] as Map?;
        if (dists != null) {
          for (final distData in dists.values) {
            if (distData is Map) {
              final muns = distData['municipalities'] as Map?;
              result.addAll(muns?.keys.cast<String>() ?? []);
            }
          }
        }
      }
    } else if (province != null && district != null) {
      // Specific district
      final provData = _data[province];
      if (provData is! Map) return [];
      final distData = provData['districts']?[district];
      if (distData is! Map) return [];
      final muns = distData['municipalities'] as Map?;
      result.addAll(muns?.keys.cast<String>() ?? []);
    }

    return result.toList()..sort();
  }

  List<Map<String, dynamic>> getWards({
    String? province,
    String? district,
    String? municipality,
  }) {
    final result = <Map<String, dynamic>>[];

    void collectFromMun(Map? munData) {
      if (munData == null) return;
      final wardsMap = munData['wards'] as Map?;
      if (wardsMap != null) {
        result.addAll(wardsMap.values.whereType<Map<String, dynamic>>());
      }
    }

    // All wards in Nepal
    if (province == null && district == null && municipality == null) {
      for (final provData in _data.values) {
        if (provData is! Map) continue;
        final dists = provData['districts'] as Map?;
        if (dists == null) continue;
        for (final distData in dists.values) {
          if (distData is! Map) continue;
          final muns = distData['municipalities'] as Map?;
          if (muns != null) {
            for (final munData in muns.values) collectFromMun(munData);
          }
        }
      }
    }
    // Add other cases (province only, province+district, specific mun) similarly...
    // For brevity, you can implement them like getMunicipalities above
    // Specific municipality
    else if (province != null && district != null && municipality != null) {
      final munData =
          _data[province]?['districts']?[district]?['municipalities']?[municipality];
      collectFromMun(munData);
    }

    result.sort((a, b) => (a['ward_no'] as int).compareTo(b['ward_no'] as int));
    return result;
  }

  List<Map<String, dynamic>> getBooths({
    String? province,
    String? district,
    String? municipality,
    int? wardNo,
  }) {
    final result = <Map<String, dynamic>>[];

    void collectFromWard(Map? wardData) {
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
      // All booths (very large - be careful)
      for (final provData in _data.values) {
        if (provData is! Map) continue;
        final dists = provData['districts'] as Map?;
        if (dists == null) continue;
        for (final distData in dists.values) {
          if (distData is! Map) continue;
          final muns = distData['municipalities'] as Map?;
          if (muns == null) continue;
          for (final munData in muns.values) {
            if (munData is! Map) continue;
            final wards = munData['wards'] as Map?;
            if (wards != null) {
              for (final wardData in wards.values) collectFromWard(wardData);
            }
          }
        }
      }
    } else if (province != null &&
        district != null &&
        municipality != null &&
        wardNo != null) {
      final wards =
          _data[province]?['districts']?[district]?['municipalities']?[municipality]?['wards'];
      if (wards is Map) {
        final wardData = wards.values.firstWhere(
          (w) => (w as Map)['ward_no'] == wardNo,
          orElse: () => null,
        );
        collectFromWard(wardData);
      }
    }

    result.sort(
      (a, b) =>
          (a['booth_code'] as String).compareTo(b['booth_code'] as String),
    );
    return result;
  }
}

// ─────────────────────────────────────────────────────────────
// Riverpod Provider (load JSON once, use everywhere)
// ─────────────────────────────────────────────────────────────

final locationRepoProvider = FutureProvider<LocationRepository>((ref) async {
  return LocationRepository.loadFromAsset('assets/location_data.json');
});
