import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/search_params.dart';
import '../models/voter.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes_list.db');

    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        final data = await rootBundle.load('assets/notes_list.db');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
        print('Copied notes_list.db from assets to $path');
      } catch (e) {
        print('Asset copy failed: $e');
      }
    } else {
      print('Using existing notes_list.db at $path');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // If the asset already has tables, onCreate won't run — that's fine.
        // But for safety, you can add minimal schema here if needed.
        print('onCreate called — but asset DB should already have tables');
      },
    );
  }

  // ── Main search method ──────────────────────────────────────────────────────
  Future<List<Voter>> searchVoters({
    required String query,
    required SearchField field,
    required SearchMatchMode mode,
    int? districtId,
    int? municipalityId,
    int? wardId,
    int? boothId,
    String? gender,
    int? minAge,
    int? maxAge,
    int limit = 300,
    int offset = 0,
  }) async {
    final db = await database;
    final joins = <String>[];
    final where = <String>[];
    final args = <dynamic>[];

    // Search condition
    final valueCol = field == SearchField.name ? 'v.name_np' : 'v.voter_no';
    final likePattern = mode == SearchMatchMode.startsWith
        ? '$query%'
        : '%$query%';
    where.add('$valueCol LIKE ? COLLATE NOCASE');
    args.add(likePattern);

    // Location filters (add more as needed)
    if (boothId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      where.add('eb.id = ?');
      args.add(boothId);
    } // ... add similar for wardId, municipalityId, districtId

    if (gender != null) {
      where.add('v.gender = ?');
      args.add(gender);
    }
    if (minAge != null) {
      where.add('v.age >= ?');
      args.add(minAge);
    }
    if (maxAge != null) {
      where.add('v.age <= ?');
      args.add(maxAge);
    }

    final sql =
        '''
      SELECT 
        v.id,
        v.voter_no AS voterId,
        v.name_np AS nameNepali,
        v.age,
        v.gender,
        v.spouse_name_np,
        v.parent_name_np
      FROM voter v
      ${joins.isNotEmpty ? joins.join(' ') : ''}
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY v.name_np ASC
      LIMIT $limit OFFSET $offset
    ''';

    print('Executing voter search:');
    print(sql);
    print('Args: $args');

    final rows = await db.rawQuery(sql, args);

    print('Found ${rows.length} voters');

    return rows.map((row) => Voter.fromMap(row)).toList();
  }

  // ── Get voter count with filters ────────────────────────────────────────────
  Future<int> getVoterCount({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    SearchField? field,
    SearchMatchMode? matchMode,
    int? provinceId,
    int? districtId,
    int? municipalityId,
    int? wardNo,
    String? boothCode,
    String? gender,
    int? minAge,
    int? maxAge,
  }) async {
    final db = await database;
    final joins = <String>[];
    final where = <String>[];
    final args = <dynamic>[];

    // Build location filters with JOINs
    if (boothCode != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      where.add('eb.booth_code = ?');
      args.add(boothCode);
    } else if (wardNo != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      where.add('w.ward_no = ?');
      args.add(wardNo);
    } else if (municipalityId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      where.add('w.municipality_id = ?');
      args.add(municipalityId);
    } else if (districtId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      joins.add('INNER JOIN municipality m ON w.municipality_id = m.id');
      where.add('m.district_id = ?');
      args.add(districtId);
    } else if (provinceId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      joins.add('INNER JOIN municipality m ON w.municipality_id = m.id');
      joins.add('INNER JOIN district d ON m.district_id = d.id');
      where.add('d.province_id = ?');
      args.add(provinceId);
    }

    // Add other filters
    if (gender != null) {
      where.add('v.gender = ?');
      args.add(gender);
    }
    if (minAge != null) {
      where.add('v.age >= ?');
      args.add(minAge);
    }
    if (maxAge != null) {
      where.add('v.age <= ?');
      args.add(maxAge);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final col = field == SearchField.voterId ? 'v.voter_no' : 'v.name_np';
      final pattern = matchMode == SearchMatchMode.startsWith
          ? '$searchQuery%'
          : '%$searchQuery%';
      where.add('$col LIKE ? COLLATE NOCASE');
      args.add(pattern);
    }
    if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
      final col = field == SearchField.voterId ? 'v.voter_no' : 'v.name_np';
      final pattern = matchMode == SearchMatchMode.startsWith
          ? '$transliteratedQuery%'
          : '%$transliteratedQuery%';
      where.add('$col LIKE ? COLLATE NOCASE');
      args.add(pattern);
    }
    if (startingLetter != null && startingLetter.isNotEmpty) {
      where.add('v.name_np LIKE ? COLLATE NOCASE');
      args.add('$startingLetter%');
    }

    final sql =
        '''
      SELECT COUNT(*) as count
      FROM voter v
      INNER JOIN election_booth eb ON v.booth_id = eb.id
      INNER JOIN ward w ON eb.ward_id = w.id
      INNER JOIN municipality m ON w.municipality_id = m.id
      INNER JOIN district d ON m.district_id = d.id
      INNER JOIN province p ON d.province_id = p.id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
    ''';

    final result = await db.rawQuery(sql, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Get voters with filters and pagination ────────────────────────────────
  Future<List<Map<String, dynamic>>> getVoters({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    SearchField? field,
    SearchMatchMode? matchMode,
    int? provinceId,
    int? districtId,
    int? municipalityId,
    int? wardNo,
    String? boothCode,
    String? gender,
    int? minAge,
    int? maxAge,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final joins = <String>[];
    final where = <String>[];
    final args = <dynamic>[];

    // Build location filters with JOINs
    if (boothCode != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      where.add('eb.booth_code = ?');
      args.add(boothCode);
    } else if (wardNo != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      where.add('w.ward_no = ?');
      args.add(wardNo);
    } else if (municipalityId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      where.add('w.municipality_id = ?');
      args.add(municipalityId);
    } else if (districtId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      joins.add('INNER JOIN municipality m ON w.municipality_id = m.id');
      where.add('m.district_id = ?');
      args.add(districtId);
    } else if (provinceId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      joins.add('INNER JOIN ward w ON eb.ward_id = w.id');
      joins.add('INNER JOIN municipality m ON w.municipality_id = m.id');
      joins.add('INNER JOIN district d ON m.district_id = d.id');
      where.add('d.province_id = ?');
      args.add(provinceId);
    }

    // Add other filters
    if (gender != null) {
      where.add('v.gender = ?');
      args.add(gender);
    }
    if (minAge != null) {
      where.add('v.age >= ?');
      args.add(minAge);
    }
    if (maxAge != null) {
      where.add('v.age <= ?');
      args.add(maxAge);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final col = field == SearchField.voterId ? 'v.voter_no' : 'v.name_np';
      final pattern = matchMode == SearchMatchMode.startsWith
          ? '$searchQuery%'
          : '%$searchQuery%';
      where.add('$col LIKE ? COLLATE NOCASE');
      args.add(pattern);
    }
    if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
      final col = field == SearchField.voterId ? 'v.voter_no' : 'v.name_np';
      final pattern = matchMode == SearchMatchMode.startsWith
          ? '$transliteratedQuery%'
          : '%$transliteratedQuery%';
      where.add('$col LIKE ? COLLATE NOCASE');
      args.add(pattern);
    }
    if (startingLetter != null && startingLetter.isNotEmpty) {
      where.add('v.name_np LIKE ? COLLATE NOCASE');
      args.add('$startingLetter%');
    }

    final sql =
        '''
      SELECT v.id, v.booth_id, v.voter_no AS voterId, v.name_np AS name, v.age, v.gender, v.spouse_name_np, v.parent_name_np AS father_name,
             eb.booth_code, eb.booth_name,
             w.ward_no,
             m.name AS municipality,
             d.name AS district,
             p.name AS province
      FROM voter v
      INNER JOIN election_booth eb ON v.booth_id = eb.id
      INNER JOIN ward w ON eb.ward_id = w.id
      INNER JOIN municipality m ON w.municipality_id = m.id
      INNER JOIN district d ON m.district_id = d.id
      INNER JOIN province p ON d.province_id = p.id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY v.name_np
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    return await db.rawQuery(sql, args);
  }

  // ── Get voter by ID ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getVoterById(int voterId) async {
    final db = await database;
    final rows = await db.query(
      'voter',
      where: 'id = ?',
      whereArgs: [voterId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  // ── Get gender stats ───────────────────────────────────────────────────────
  Future<Map<String, int>> getGenderStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male,
        SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female
      FROM voter
    ''');
    final row = result.first;
    return {
      'total': row['total'] as int,
      'male': row['male'] as int? ?? 0,
      'female': row['female'] as int? ?? 0,
    };
  }

  // ── Get analytics data ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAnalyticsData({
    String? searchQuery,
    String? startingLetter,
    int? provinceId,
    int? districtId,
    int? municipalityId,
    int? wardNo,
    String? boothCode,
    String? gender,
    int? minAge,
    int? maxAge,
    String? groupBy,
  }) async {
    final db = await database;
    // Implement analytics query
    return {'total': 0, 'male': 0, 'female': 0};
  }

  // ── Helper methods for location IDs ────────────────────────────────────────
  Future<int?> getProvinceIdByName(String name) async {
    final db = await database;
    final rows = await db.query(
      'province',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['id'] as int : null;
  }

  Future<int?> getDistrictIdByName(String name) async {
    final db = await database;
    final rows = await db.query(
      'district',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['id'] as int : null;
  }

  Future<int?> getMunicipalityIdByName(String name) async {
    final db = await database;
    final rows = await db.query(
      'municipality',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['id'] as int : null;
  }
}
