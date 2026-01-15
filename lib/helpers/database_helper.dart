import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/search_models.dart';

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
    final path = join(dbPath, 'voter_koshi.db');

    // Copy pre-filled DB from assets on first run (recommended for Nepal data)
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        final data = await rootBundle.load('assets/voter_koshi.db');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print('Asset DB copy failed: $e');
      }
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Your schema CREATE statements here (paste them all)
        // province, district, municipality, ward, election_booth, voter, ...
        // Example snippet:
        await db.execute('''
          CREATE TABLE voter (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            booth_id INTEGER NOT NULL,
            voter_no TEXT NOT NULL,
            name_np TEXT NOT NULL,
            age INTEGER,
            gender TEXT,
            spouse_name_np TEXT,
            parent_name_np TEXT,
            FOREIGN KEY (booth_id) REFERENCES election_booth(id),
            UNIQUE (booth_id, voter_no)
          )
        ''');
        // Add indexes
        await db.execute(
          'CREATE INDEX idx_voter_name ON voter(name_np COLLATE NOCASE)',
        );
        await db.execute('CREATE INDEX idx_voter_vno ON voter(voter_no)');
      },
    );
  }

  // ── Search Voters with Location Filters ─────────────────────────────────────
  Future<List<Voter>> searchVoters({
    required String query,
    required SearchField field,
    required SearchMatchMode mode,
    int? districtId,
    int? municipalityId,
    int? wardId,
    int? boothId,
  }) async {
    final db = await database;
    final joins = <String>[];
    final where = <String>[];
    final args = <dynamic>[];

    // Build search condition
    String valueCol = field == SearchField.name ? 'name_np' : 'voter_no';
    String likePattern = mode == SearchMatchMode.startsWith
        ? '$query%'
        : '%$query%';
    where.add('$valueCol LIKE ? COLLATE NOCASE');
    args.add(likePattern);

    // Build location filters with JOINs
    if (boothId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      where.add('eb.id = ?');
      args.add(boothId);
    } else if (wardId != null) {
      joins.add('INNER JOIN election_booth eb ON v.booth_id = eb.id');
      where.add('eb.ward_id = ?');
      args.add(wardId);
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
    }

    final sql =
        '''
      SELECT v.id, v.name_np AS name, v.voter_no AS voterId, v.gender
      FROM voter v
      ${joins.join(' ')}
      WHERE ${where.join(' AND ')}
      ORDER BY v.name_np
      LIMIT 300
    ''';

    final rows = await db.rawQuery(sql, args);
    return rows.map((row) => Voter.fromMap(row)).toList();
  }

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
}

// Update your Voter model
class Voter {
  final int? id;
  final String name;
  final String voterId;
  final String gender;

  Voter({
    this.id,
    required this.name,
    required this.voterId,
    required this.gender,
  });

  factory Voter.fromMap(Map<String, dynamic> map) {
    return Voter(
      id: map['id'] as int?,
      name: map['name'] as String,
      voterId: map['voterId'] as String,
      gender: map['gender'] as String? ?? 'U',
    );
  }
}
