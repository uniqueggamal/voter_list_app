import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  // In-memory cache for name → ID lookups (fast for filters)
  final Map<String, int?> _provinceIdCache = {};
  final Map<String, int?> _districtIdCache = {};
  final Map<String, int?> _municipalityIdCache = {};

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'notes_list.db');

    // Debug path (only in debug mode)
    if (kDebugMode) {
      debugPrint('DB Path: $path');
    }

    final exists = await databaseExists(path);

    if (!exists) {
      // Create directory if needed
      await Directory(dirname(path)).create(recursive: true);

      // Copy from assets
      try {
        final data = await rootBundle.load('assets/notes_list.db');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);

        if (kDebugMode) {
          debugPrint('DB copied from assets (${bytes.length} bytes)');
        }
      } catch (e) {
        debugPrint('Failed to copy DB from assets: $e');
        rethrow;
      }
    }

    // Open database (read-only)
    try {
      final db = await openDatabase(
        path,
        readOnly: true,
        onConfigure: (db) async {
          // Enable foreign keys (if needed)
          await db.execute('PRAGMA foreign_keys = ON;');
        },
      );

      if (kDebugMode) {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM voter'),
        );
        debugPrint('DB opened - Voters count: $count');
      }

      return db;
    } catch (e) {
      debugPrint('Failed to open DB: $e');
      // Retry copy on failure (e.g., corrupted file)
      try {
        final data = await rootBundle.load('assets/notes_list.db');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);

        final db = await openDatabase(path, readOnly: true);
        debugPrint('DB recovered and reopened');
        return db;
      } catch (retryError) {
        debugPrint('Retry failed: $retryError');
        rethrow;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Voter List Query (paginated + filtered)
  // ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getVoters({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    String? boothCode,
    int? wardNo,
    int? municipalityId,
    int? districtId,
    int? provinceId,
    String? gender,
    int? minAge,
    int? maxAge,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <dynamic>[];

    // Search (English/Nepali)
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      where.add('(v.name_np LIKE ? OR v.voter_no LIKE ?)');
      args.addAll([q, q]);

      if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
        final tq = '%${transliteratedQuery.trim()}%';
        where.add('(v.name_np LIKE ? OR v.voter_no LIKE ?)');
        args.addAll([tq, tq]);
      }
    }

    if (boothCode != null && boothCode.isNotEmpty) {
      where.add('b.booth_code = ?');
      args.add(boothCode);
    }
    if (wardNo != null) {
      where.add('w.ward_no = ?');
      args.add(wardNo);
    }
    if (municipalityId != null) {
      where.add('m.id = ?');
      args.add(municipalityId);
    }
    if (districtId != null) {
      where.add('d.id = ?');
      args.add(districtId);
    }
    if (provinceId != null) {
      where.add('p.id = ?');
      args.add(provinceId);
    }
    if (gender != null && gender.isNotEmpty) {
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
    if (startingLetter != null && startingLetter.isNotEmpty) {
      where.add('v.name_np LIKE ?');
      args.add('$startingLetter%');
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final limitClause = limit != null ? 'LIMIT ? OFFSET ?' : '';

    final query =
        '''
      SELECT
        v.id,
        v.voter_no,
        v.name_np,
        v.age,
        v.gender,
        b.booth_code,
        b.booth_name,
        w.ward_no,
        m.name as municipality,
        m.type as municipality_code,
        d.name as district,
        p.name as province
      FROM voter v
      JOIN election_booth b ON v.booth_id = b.id
      JOIN ward w ON b.ward_id = w.id
      JOIN municipality m ON w.municipality_id = m.id
      JOIN district d ON m.district_id = d.id
      JOIN province p ON d.province_id = p.id
      $whereClause
      ORDER BY v.id
      $limitClause
    ''';

    if (limit != null) {
      args.add(limit);
      args.add(offset ?? 0);
    }

    return db.rawQuery(query, args);
  }

  // ─────────────────────────────────────────────────────────────
  // Count (for pagination)
  // ─────────────────────────────────────────────────────────────
  Future<int> getVoterCount({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    String? boothCode,
    int? wardNo,
    int? municipalityId,
    int? districtId,
    int? provinceId,
    String? gender,
    int? minAge,
    int? maxAge,
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <dynamic>[];

    // Same filtering logic as getVoters
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      where.add('(v.name_np LIKE ? OR v.voter_no LIKE ?)');
      args.addAll([q, q]);

      if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
        final tq = '%${transliteratedQuery.trim()}%';
        where.add('(v.name_np LIKE ? OR v.voter_no LIKE ?)');
        args.addAll([tq, tq]);
      }
    }

    if (boothCode != null && boothCode.isNotEmpty) {
      where.add('b.booth_code = ?');
      args.add(boothCode);
    }
    if (wardNo != null) {
      where.add('w.ward_no = ?');
      args.add(wardNo);
    }
    if (municipalityId != null) {
      where.add('m.id = ?');
      args.add(municipalityId);
    }
    if (districtId != null) {
      where.add('d.id = ?');
      args.add(districtId);
    }
    if (provinceId != null) {
      where.add('p.id = ?');
      args.add(provinceId);
    }
    if (gender != null && gender.isNotEmpty) {
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
    if (startingLetter != null && startingLetter.isNotEmpty) {
      where.add('v.name_np LIKE ?');
      args.add('$startingLetter%');
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM voter v
      JOIN election_booth b ON v.booth_id = b.id
      JOIN ward w ON b.ward_id = w.id
      JOIN municipality m ON w.municipality_id = m.id
      JOIN district d ON m.district_id = d.id
      JOIN province p ON d.province_id = p.id
      $whereClause
    ''', args);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>> getVoterDetails(int voterId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT
      v.*,
      b.booth_code,
      b.booth_name,
      w.ward_no,
      m.name as municipality,
      m.type as municipality_code,
      d.name as district,
      p.name as province
    FROM voter v
    JOIN election_booth b ON v.booth_id = b.id
    JOIN ward w ON b.ward_id = w.id
    JOIN municipality m ON w.municipality_id = m.id
    JOIN district d ON m.district_id = d.id
    JOIN province p ON d.province_id = p.id
    WHERE v.id = ?
  ''',
      [voterId],
    );

    return result.isNotEmpty ? result.first : {};
  }

  // ─────────────────────────────────────────────────────────────
  // Location Lookups (with cache)
  // ─────────────────────────────────────────────────────────────
  Future<int?> getProvinceIdByName(String? name) async {
    if (name == null || name.isEmpty) return null;
    if (_provinceIdCache.containsKey(name)) return _provinceIdCache[name];

    final db = await database;
    final result = await db.query(
      'province',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    final id = result.isNotEmpty ? result.first['id'] as int? : null;
    _provinceIdCache[name] = id;
    return id;
  }

  Future<int?> getDistrictIdByName(String? name) async {
    if (name == null || name.isEmpty) return null;
    if (_districtIdCache.containsKey(name)) return _districtIdCache[name];

    final db = await database;
    final result = await db.query(
      'district',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    final id = result.isNotEmpty ? result.first['id'] as int? : null;
    _districtIdCache[name] = id;
    return id;
  }

  Future<int?> getMunicipalityIdByName(String? name) async {
    if (name == null || name.isEmpty) return null;
    if (_municipalityIdCache.containsKey(name))
      return _municipalityIdCache[name];

    final db = await database;
    final result = await db.query(
      'municipality',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    final id = result.isNotEmpty ? result.first['id'] as int? : null;
    _municipalityIdCache[name] = id;
    return id;
  }

  // ─────────────────────────────────────────────────────────────
  // Analytics (summary + grouped)
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAnalyticsData({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    String? boothCode,
    int? wardNo,
    int? municipalityId,
    int? districtId,
    int? provinceId,
    String? gender,
    int? minAge,
    int? maxAge,
    required String groupBy,
  }) async {
    final db = await database;

    // Build WHERE clause (same as getVoterCount)
    final where = <String>[];
    final args = <dynamic>[];

    // Same filtering logic as getVoterCount
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      where.add('(v.name_np LIKE ? OR v.voter_no LIKE ?)');
      args.addAll([q, q]);

      if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
        final tq = '%${transliteratedQuery.trim()}%';
        where.add('(v.name_np LIKE ? OR v.voter_no LIKE ?)');
        args.addAll([tq, tq]);
      }
    }

    if (boothCode != null && boothCode.isNotEmpty) {
      where.add('b.booth_code = ?');
      args.add(boothCode);
    }
    if (wardNo != null) {
      where.add('w.ward_no = ?');
      args.add(wardNo);
    }
    if (municipalityId != null) {
      where.add('m.id = ?');
      args.add(municipalityId);
    }
    if (districtId != null) {
      where.add('d.id = ?');
      args.add(districtId);
    }
    if (provinceId != null) {
      where.add('p.id = ?');
      args.add(provinceId);
    }
    if (gender != null && gender.isNotEmpty) {
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
    if (startingLetter != null && startingLetter.isNotEmpty) {
      where.add('v.name_np LIKE ?');
      args.add('$startingLetter%');
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    // Summary stats
    final summaryResult = await db.rawQuery('''
      SELECT
        COUNT(*) as total_voters,
        ROUND(AVG(age), 1) as avg_age,
        COUNT(CASE WHEN gender = 'Male' THEN 1 END) as male_count,
        COUNT(CASE WHEN gender = 'Female' THEN 1 END) as female_count,
        COUNT(DISTINCT b.id) as booth_count,
        COUNT(DISTINCT w.id) as ward_count
      FROM voter v
      JOIN election_booth b ON v.booth_id = b.id
      JOIN ward w ON b.ward_id = w.id
      JOIN municipality m ON w.municipality_id = m.id
      JOIN district d ON m.district_id = d.id
      JOIN province p ON d.province_id = p.id
      $whereClause
    ''', args);

    final summary = summaryResult.first;

    // Grouped stats
    final groupColumn = _getGroupByColumn(groupBy);
    final groupLabel = _getGroupByLabel(groupBy);

    final groupResult = await db.rawQuery('''
      SELECT
        $groupLabel as name,
        COUNT(*) as total_voters,
        COUNT(CASE WHEN gender = 'Male' THEN 1 END) as male_count,
        COUNT(CASE WHEN gender = 'Female' THEN 1 END) as female_count
      FROM voter v
      JOIN election_booth b ON v.booth_id = b.id
      JOIN ward w ON b.ward_id = w.id
      JOIN municipality m ON w.municipality_id = m.id
      JOIN district d ON m.district_id = d.id
      JOIN province p ON d.province_id = p.id
      $whereClause
      GROUP BY $groupColumn
      ORDER BY total_voters DESC
      LIMIT 50  -- prevent too large response
    ''', args);

    return {'summary': summary, 'groups': groupResult};
  }

  String _getGroupByColumn(String groupBy) {
    switch (groupBy.toLowerCase()) {
      case 'province':
        return 'p.id';
      case 'district':
        return 'd.id';
      case 'municipality':
        return 'm.id';
      case 'ward':
        return 'w.id';
      case 'booth':
        return 'b.id';
      default:
        return 'p.id';
    }
  }

  String _getGroupByLabel(String groupBy) {
    switch (groupBy.toLowerCase()) {
      case 'province':
        return 'p.name';
      case 'district':
        return 'd.name';
      case 'municipality':
        return 'm.name';
      case 'ward':
        return 'w.ward_no || " - " || m.name';
      case 'booth':
        return 'b.booth_name || " (" || b.booth_code || ")"';
      default:
        return 'p.name';
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
