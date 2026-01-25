// Abstract interface for location data access
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../helpers/database_helper.dart';

abstract class ILocationRepository {
  Future<List<String>> getProvinces();
  Future<List<String>> getDistricts({String? province});
  Future<List<String>> getMunicipalities({String? province, String? district});
  Future<List<Map<String, dynamic>>> getWards({
    String? province,
    String? district,
    String? municipality,
  });
  Future<List<Map<String, dynamic>>> getBooths({
    String? province,
    String? district,
    String? municipality,
    int? wardNo,
  });
}

// JSON implementation (current)
class JsonLocationRepository implements ILocationRepository {
  final Map<String, dynamic> _data;

  JsonLocationRepository(this._data);

  static Future<JsonLocationRepository> loadFromAsset(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    return JsonLocationRepository(jsonData);
  }

  @override
  Future<List<String>> getProvinces() async {
    return _data.keys.whereType<String>().toList()..sort();
  }

  @override
  Future<List<String>> getDistricts({String? province}) async {
    final result = <String>[];
    if (province == null) {
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
    return result..sort();
  }

  @override
  Future<List<String>> getMunicipalities({
    String? province,
    String? district,
  }) async {
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

  @override
  Future<List<Map<String, dynamic>>> getWards({
    String? province,
    String? district,
    String? municipality,
  }) async {
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

  @override
  Future<List<Map<String, dynamic>>> getBooths({
    String? province,
    String? district,
    String? municipality,
    int? wardNo,
  }) async {
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

// Database implementation (for future migration)
class DatabaseLocationRepository implements ILocationRepository {
  final DatabaseHelper _dbHelper;

  DatabaseLocationRepository(this._dbHelper);

  @override
  Future<List<String>> getProvinces() async {
    final db = await _dbHelper.database;
    final results = await db.query('province', columns: ['name']);
    return results.map((row) => row['name'] as String).toList()..sort();
  }

  @override
  Future<List<String>> getDistricts({String? province}) async {
    final db = await _dbHelper.database;
    final where = province != null ? 'province_name = ?' : null;
    final whereArgs = province != null ? [province] : null;
    final results = await db.query(
      'district',
      columns: ['name'],
      where: where,
      whereArgs: whereArgs,
    );
    return results.map((row) => row['name'] as String).toList()..sort();
  }

  @override
  Future<List<String>> getMunicipalities({
    String? province,
    String? district,
  }) async {
    final db = await _dbHelper.database;
    var where = '';
    final whereArgs = <String>[];

    if (province != null) {
      where += 'province_name = ?';
      whereArgs.add(province);
    }
    if (district != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'district_name = ?';
      whereArgs.add(district);
    }

    final results = await db.query(
      'municipality',
      columns: ['name'],
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
    return results.map((row) => row['name'] as String).toList()..sort();
  }

  @override
  Future<List<Map<String, dynamic>>> getWards({
    String? province,
    String? district,
    String? municipality,
  }) async {
    final db = await _dbHelper.database;
    var where = '';
    final whereArgs = <String>[];

    if (province != null) {
      where += 'province_name = ?';
      whereArgs.add(province);
    }
    if (district != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'district_name = ?';
      whereArgs.add(district);
    }
    if (municipality != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'municipality_name = ?';
      whereArgs.add(municipality);
    }

    final results = await db.query(
      'ward',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'ward_no',
    );
    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getBooths({
    String? province,
    String? district,
    String? municipality,
    int? wardNo,
  }) async {
    final db = await _dbHelper.database;
    var where = '';
    final whereArgs = <dynamic>[];

    if (province != null) {
      where += 'province_name = ?';
      whereArgs.add(province);
    }
    if (district != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'district_name = ?';
      whereArgs.add(district);
    }
    if (municipality != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'municipality_name = ?';
      whereArgs.add(municipality);
    }
    if (wardNo != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'ward_no = ?';
      whereArgs.add(wardNo);
    }

    final results = await db.query(
      'booth',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'booth_code',
    );
    return results;
  }
}
