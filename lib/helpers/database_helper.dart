import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/voter.dart';
import '../models/search_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  static DatabaseHelper get instance => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'voter_list_readable.db');

    // Check if the database exists
    bool exists = await databaseExists(path);

    if (!exists) {
      // Copy from asset
      ByteData data = await rootBundle.load(
        join('assets', 'db', 'voter_list_readable.db'),
      );
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create voterdetails table with updated schema for new installations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS voterdetails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voterid INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        social_media TEXT,
        description TEXT,
        FOREIGN KEY (voterid) REFERENCES voter(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case 1:
        // Upgrade from version 1 to 2: Modify voterdetails table
        final columns = await db.rawQuery('PRAGMA table_info(voterdetails)');
        final columnNames = columns.map((c) => c['name'] as String).toList();

        if (!columnNames.contains('description')) {
          await db.execute(
            'ALTER TABLE voterdetails ADD COLUMN description TEXT',
          );
        }

        if (columnNames.contains('landline')) {
          await db.execute('ALTER TABLE voterdetails DROP COLUMN landline');
        }
        break;
      default:
        break;
    }
  }

  // Method to force refresh database from assets
  Future<void> forceRefreshDatabase() async {
    // Close current database connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete existing database file
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'voter_list_readable.db');

    if (await databaseExists(path)) {
      await deleteDatabase(path);
    }

    // Force re-initialization
    _database = await _initDatabase();
  }

  // Province methods
  Future<List<Map<String, dynamic>>> getProvinces() async {
    Database db = await database;
    return await db.query('province');
  }

  Future<Map<String, dynamic>?> getProvince(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'province',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // District methods
  Future<List<Map<String, dynamic>>> getDistricts() async {
    Database db = await database;
    return await db.query('district');
  }

  Future<List<Map<String, dynamic>>> getDistrictsByProvince(
    int provinceId,
  ) async {
    Database db = await database;
    return await db.query(
      'district',
      where: 'province_id = ?',
      whereArgs: [provinceId],
    );
  }

  Future<Map<String, dynamic>?> getDistrict(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'district',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Municipality methods
  Future<List<Map<String, dynamic>>> getMunicipalities() async {
    Database db = await database;
    return await db.query('municipality');
  }

  Future<List<Map<String, dynamic>>> getMunicipalitiesByDistrict(
    int districtId,
  ) async {
    Database db = await database;
    return await db.query(
      'municipality',
      where: 'district_id = ?',
      whereArgs: [districtId],
    );
  }

  Future<Map<String, dynamic>?> getMunicipality(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'municipality',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Ward methods
  Future<List<Map<String, dynamic>>> getWards() async {
    Database db = await database;
    return await db.query('ward');
  }

  Future<List<Map<String, dynamic>>> getWardsByMunicipality(
    int municipalityId,
  ) async {
    Database db = await database;
    return await db.query(
      'ward',
      where: 'municipality_id = ?',
      whereArgs: [municipalityId],
    );
  }

  Future<Map<String, dynamic>?> getWard(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'ward',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Election Booth methods
  Future<List<Map<String, dynamic>>> getElectionBooths() async {
    Database db = await database;
    return await db.query('election_booth');
  }

  Future<List<Map<String, dynamic>>> getElectionBoothsByWard(int wardId) async {
    Database db = await database;
    return await db.query(
      'election_booth',
      where: 'ward_id = ?',
      whereArgs: [wardId],
    );
  }

  Future<Map<String, dynamic>?> getElectionBooth(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'election_booth',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Voter methods
  Future<List<Map<String, dynamic>>> getVoters({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    String? field,
    String? matchMode,
    int? provinceId,
    int? districtId,
    int? municipalityId,
    int? wardNo,
    String? boothCode,
    String? gender,
    int? minAge,
    int? maxAge,
    String? mainCategory,
    int? limit,
    int? offset,
  }) async {
    Database db = await database;
    String query = '''
      SELECT v.*, eb.booth_code, eb.booth_name, w.ward_no, m.name as municipality_name,
             d.name as district_name, p.name as province_name,
             COALESCE(c.Mname, 'Unrecognized') as main_category
      FROM voter v
      LEFT JOIN election_booth eb ON v.booth_id = eb.id
      LEFT JOIN ward w ON eb.ward_id = w.id
      LEFT JOIN municipality m ON w.municipality_id = m.id
      LEFT JOIN district d ON m.district_id = d.id
      LEFT JOIN province p ON d.province_id = p.id
      LEFT JOIN categorized c ON v.voter_no = c.voter_no
      WHERE 1=1
    ''';

    List<dynamic> args = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Determine which column to search based on field parameter
      String searchColumn = 'v.name_np'; // default to name
      if (field == 'voterId' || field == 'voter_id') {
        searchColumn = 'v.voter_no';
      }

      query += ' AND $searchColumn LIKE ?';
      args.add('%$searchQuery%');
    }

    if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
      query += ' AND v.name_np LIKE ?';
      args.add('%$transliteratedQuery%');
    }

    if (startingLetter != null && startingLetter.isNotEmpty) {
      query += ' AND v.name_np LIKE ?';
      args.add('$startingLetter%');
    }

    if (provinceId != null) {
      query += ' AND p.id = ?';
      args.add(provinceId);
    }

    if (districtId != null) {
      query += ' AND d.id = ?';
      args.add(districtId);
    }

    if (municipalityId != null) {
      query += ' AND m.id = ?';
      args.add(municipalityId);
    }

    if (wardNo != null) {
      query += ' AND w.ward_no = ?';
      args.add(wardNo);
    }

    if (boothCode != null && boothCode.isNotEmpty) {
      query += ' AND eb.booth_code = ?';
      args.add(boothCode);
    }

    if (gender != null && gender.isNotEmpty && gender != 'All') {
      query += ' AND v.gender = ?';
      args.add(gender);
    }

    if (minAge != null) {
      query += ' AND v.age >= ?';
      args.add(minAge);
    }

    if (maxAge != null) {
      query += ' AND v.age <= ?';
      args.add(maxAge);
    }

    if (mainCategory != null &&
        mainCategory.isNotEmpty &&
        mainCategory != 'All') {
      query += ' AND COALESCE(c.Mname, \'Unrecognized\') = ?';
      args.add(mainCategory);
    }

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    if (offset != null) {
      query += ' OFFSET ?';
      args.add(offset);
    }

    return await db.rawQuery(query, args);
  }

  Future<List<Map<String, dynamic>>> getVotersByBooth(int boothId) async {
    Database db = await database;
    return await db.query('voter', where: 'booth_id = ?', whereArgs: [boothId]);
  }

  Future<Map<String, dynamic>?> getVoter(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT v.*, eb.booth_code, eb.booth_name as boothName, w.ward_no,
             m.name as municipality, m.id as municipalityId,
             d.name as district, d.id as districtId,
             p.name as province, p.id as provinceId,
             c.Mname as main_category, c.Sname as sub_category
      FROM voter v
      LEFT JOIN election_booth eb ON v.booth_id = eb.id
      LEFT JOIN ward w ON eb.ward_id = w.id
      LEFT JOIN municipality m ON w.municipality_id = m.id
      LEFT JOIN district d ON m.district_id = d.id
      LEFT JOIN province p ON d.province_id = p.id
      LEFT JOIN categorized c ON v.voter_no = c.voter_no
      WHERE v.id = ?
    ''',
      [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> searchVotersByName(String name) async {
    Database db = await database;
    return await db.query(
      'voter',
      where: 'name_np LIKE ?',
      whereArgs: ['%$name%'],
    );
  }

  Future<List<Map<String, dynamic>>> getVotersByAgeRange(
    int minAge,
    int maxAge,
  ) async {
    Database db = await database;
    return await db.query(
      'voter',
      where: 'age BETWEEN ? AND ?',
      whereArgs: [minAge, maxAge],
    );
  }

  Future<List<Map<String, dynamic>>> getVotersByGender(String gender) async {
    Database db = await database;
    return await db.query('voter', where: 'gender = ?', whereArgs: [gender]);
  }

  // VoterDetails methods
  Future<List<Map<String, dynamic>>> getVoterDetails() async {
    Database db = await database;
    return await db.query('voterdetails');
  }

  Future<Map<String, dynamic>?> getVoterDetail(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'voterdetails',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getVoterDetailByVoterId(int voterId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'voterdetails',
      where: 'voterid = ?',
      whereArgs: [voterId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Tags methods
  Future<List<Map<String, dynamic>>> getTags() async {
    Database db = await database;
    return await db.query('tags');
  }

  Future<Map<String, dynamic>?> getTag(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getTagsByCategory(String category) async {
    Database db = await database;
    return await db.query('tags', where: 'category = ?', whereArgs: [category]);
  }

  // Voter Tag methods
  Future<List<Map<String, dynamic>>> getVoterTags() async {
    Database db = await database;
    return await db.query('voter_tag');
  }

  Future<List<Map<String, dynamic>>> getVoterTagsByVoterDetail(
    int voterDetailId,
  ) async {
    Database db = await database;
    return await db.query(
      'voter_tag',
      where: 'voterdetail_id = ?',
      whereArgs: [voterDetailId],
    );
  }

  Future<List<Map<String, dynamic>>> getVoterTagsByTag(int tagId) async {
    Database db = await database;
    return await db.query('voter_tag', where: 'tag_id = ?', whereArgs: [tagId]);
  }

  // Get active tags for a voter
  Future<List<Map<String, dynamic>>> getActiveTagsForVoter(int voterId) async {
    Database db = await database;
    return await db.rawQuery(
      '''
      SELECT t.name, t.category, t.color
      FROM tags t
      INNER JOIN voter_tag vt ON t.id = vt.tag_id
      INNER JOIN voterdetails vd ON vt.voterdetail_id = vd.id
      WHERE vd.voterid = ?
      ORDER BY t.category, t.name
    ''',
      [voterId],
    );
  }

  // Group Category methods (Main Ethnic Category)
  Future<List<Map<String, dynamic>>> getMainEthnicCategories() async {
    Database db = await database;
    return await db.query('main_ethnic_category');
  }

  Future<Map<String, dynamic>?> getMainEthnicCategory(int gid) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'group_category',
      where: 'GID = ?',
      whereArgs: [gid],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Sub Category methods
  Future<List<Map<String, dynamic>>> getSubEthnicCategories() async {
    Database db = await database;
    return await db.query('sub_category');
  }

  Future<List<Map<String, dynamic>>> getSubEthnicCategoriesByMain(
    int gid,
  ) async {
    Database db = await database;
    return await db.query('sub_category', where: 'GID = ?', whereArgs: [gid]);
  }

  Future<Map<String, dynamic>?> getSubEthnicCategory(int sid) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'sub_category',
      where: 'SID = ?',
      whereArgs: [sid],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Last Names methods
  Future<List<Map<String, dynamic>>> getLastnames() async {
    Database db = await database;
    return await db.query('last_names');
  }

  Future<List<Map<String, dynamic>>> getLastnamesBySubEthnic(int sid) async {
    Database db = await database;
    return await db.query('last_names', where: 'SID = ?', whereArgs: [sid]);
  }

  Future<Map<String, dynamic>?> getLastname(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'last_names',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> searchLastnames(String query) async {
    Database db = await database;
    return await db.query(
      'last_names',
      where: 'Lname LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Complex queries
  Future<List<Map<String, dynamic>>> getVotersWithDetails() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT v.*, vd.name, vd.phone, vd.landline, vd.social_media
      FROM voter v
      LEFT JOIN voterdetails vd ON v.id = vd.voterid
    ''');
  }

  Future<List<Map<String, dynamic>>> getVotersByLocation(
    int provinceId,
    int districtId,
    int municipalityId,
    int wardId,
  ) async {
    Database db = await database;
    return await db.rawQuery(
      '''
      SELECT v.*
      FROM voter v
      JOIN election_booth eb ON v.booth_id = eb.id
      JOIN ward w ON eb.ward_id = w.id
      JOIN municipality m ON w.municipality_id = m.id
      JOIN district d ON m.district_id = d.id
      JOIN province p ON d.province_id = p.id
      WHERE p.id = ? AND d.id = ? AND m.id = ? AND w.id = ?
    ''',
      [provinceId, districtId, municipalityId, wardId],
    );
  }

  Future<List<Map<String, dynamic>>> getVotersByEthnicCategory(
    int mid,
    int sid,
  ) async {
    Database db = await database;
    return await db.rawQuery(
      '''
      SELECT v.*
      FROM voter v
      JOIN categorized c ON v.voter_no = c.voter_no
      WHERE c.Mname = (SELECT Mname FROM main_ethnic_category WHERE MID = ?)
      AND c.Sname = (SELECT Sname FROM sub_ethnic_category WHERE SID = ?)
    ''',
      [mid, sid],
    );
  }

  // Additional methods for compatibility
  Future<Map<String, dynamic>?> getVoterById(int id) async {
    return await getVoter(id);
  }

  Future<int?> getProvinceIdByName(String name) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'province',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first['id'] : null;
  }

  Future<int?> getDistrictIdByName(String name) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'district',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first['id'] : null;
  }

  Future<int?> getMunicipalityIdByName(String name) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'municipality',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first['id'] : null;
  }

  Future<List<Map<String, dynamic>>> searchVoters({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    String? field,
    String? matchMode,
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
    Database db = await database;
    String query = '''
      SELECT v.*, eb.booth_code, w.ward_no, m.name as municipality_name,
             d.name as district_name, p.name as province_name
      FROM voter v
      LEFT JOIN election_booth eb ON v.booth_id = eb.id
      LEFT JOIN ward w ON eb.ward_id = w.id
      LEFT JOIN municipality m ON w.municipality_id = m.id
      LEFT JOIN district d ON m.district_id = d.id
      LEFT JOIN province p ON d.province_id = p.id
      WHERE 1=1
    ''';

    List<dynamic> args = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND v.name_np LIKE ?';
      args.add('%$searchQuery%');
    }

    if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
      query += ' AND v.name_np LIKE ?';
      args.add('%$transliteratedQuery%');
    }

    if (startingLetter != null && startingLetter.isNotEmpty) {
      query += ' AND v.name_np LIKE ?';
      args.add('$startingLetter%');
    }

    if (provinceId != null) {
      query += ' AND p.id = ?';
      args.add(provinceId);
    }

    if (districtId != null) {
      query += ' AND d.id = ?';
      args.add(districtId);
    }

    if (municipalityId != null) {
      query += ' AND m.id = ?';
      args.add(municipalityId);
    }

    if (wardNo != null) {
      query += ' AND w.ward_no = ?';
      args.add(wardNo);
    }

    if (boothCode != null && boothCode.isNotEmpty) {
      query += ' AND eb.booth_code = ?';
      args.add(boothCode);
    }

    if (gender != null && gender.isNotEmpty) {
      query += ' AND v.gender = ?';
      args.add(gender);
    }

    if (minAge != null) {
      query += ' AND v.age >= ?';
      args.add(minAge);
    }

    if (maxAge != null) {
      query += ' AND v.age <= ?';
      args.add(maxAge);
    }

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    if (offset != null) {
      query += ' OFFSET ?';
      args.add(offset);
    }

    return await db.rawQuery(query, args);
  }

  Future<Map<String, dynamic>> getAnalyticsData({
    String? searchQuery,
    String? transliteratedQuery,
    String? startingLetter,
    String? field,
    String? matchMode,
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
    // String? groupBy,
  }) async {
    Database db = await database;

    // Build the base query with filters
    String baseQuery = '''
      FROM voter v
      LEFT JOIN election_booth eb ON v.booth_id = eb.id
      LEFT JOIN ward w ON eb.ward_id = w.id
      LEFT JOIN municipality m ON w.municipality_id = m.id
      LEFT JOIN district d ON m.district_id = d.id
      LEFT JOIN province p ON d.province_id = p.id
      WHERE 1=1
    ''';

    List<dynamic> args = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      baseQuery += ' AND v.name_np LIKE ?';
      args.add('%$searchQuery%');
    }

    if (transliteratedQuery != null && transliteratedQuery.isNotEmpty) {
      baseQuery += ' AND v.name_np LIKE ?';
      args.add('%$transliteratedQuery%');
    }

    if (startingLetter != null && startingLetter.isNotEmpty) {
      baseQuery += ' AND v.name_np LIKE ?';
      args.add('$startingLetter%');
    }

    if (provinceId != null) {
      baseQuery += ' AND p.id = ?';
      args.add(provinceId);
    }

    if (districtId != null) {
      baseQuery += ' AND d.id = ?';
      args.add(districtId);
    }

    if (municipalityId != null) {
      baseQuery += ' AND m.id = ?';
      args.add(municipalityId);
    }

    if (wardNo != null) {
      baseQuery += ' AND w.ward_no = ?';
      args.add(wardNo);
    }

    if (boothCode != null && boothCode.isNotEmpty) {
      baseQuery += ' AND eb.booth_code = ?';
      args.add(boothCode);
    }

    if (gender != null && gender.isNotEmpty) {
      baseQuery += ' AND v.gender = ?';
      args.add(gender);
    }

    if (minAge != null) {
      baseQuery += ' AND v.age >= ?';
      args.add(minAge);
    }

    if (maxAge != null) {
      baseQuery += ' AND v.age <= ?';
      args.add(maxAge);
    }

    // Get total voters with filters
    List<Map<String, dynamic>> totalVotersResult = await db.rawQuery(
      'SELECT COUNT(*) as total $baseQuery',
      args,
    );
    int totalVoters = totalVotersResult.first['total'] as int;

    // Get average age with filters
    List<Map<String, dynamic>> avgAgeResult = await db.rawQuery(
      'SELECT AVG(v.age) as avg_age $baseQuery',
      args,
    );
    double avgAge = (avgAgeResult.first['avg_age'] as num?)?.toDouble() ?? 0.0;

    // Get gender distribution with filters
    List<Map<String, dynamic>> genderStats = await db.rawQuery('''
      SELECT v.gender, COUNT(*) as count
      $baseQuery
      GROUP BY v.gender
    ''', args);

    int maleCount = 0;
    int femaleCount = 0;
    for (var stat in genderStats) {
      String genderKey = stat['gender'] as String;
      int count = stat['count'] as int;
      if (genderKey.toLowerCase() == 'male' || genderKey.toLowerCase() == 'm') {
        maleCount = count;
      } else if (genderKey.toLowerCase() == 'female' ||
          genderKey.toLowerCase() == 'f') {
        femaleCount = count;
      }
    }

    // Get booth count
    List<Map<String, dynamic>> boothCountResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT eb.id) as count FROM election_booth eb',
    );
    int boothCount = boothCountResult.first['count'] as int;

    // Get ward count
    List<Map<String, dynamic>> wardCountResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT w.id) as count FROM ward w',
    );
    int wardCount = wardCountResult.first['count'] as int;

    // Get age groups
    List<Map<String, dynamic>> ageGroupsResult = await db.rawQuery('''
      SELECT
        CASE
          WHEN v.age BETWEEN 18 AND 30 THEN '18-30'
          WHEN v.age BETWEEN 31 AND 45 THEN '31-45'
          WHEN v.age BETWEEN 46 AND 60 THEN '46-60'
          WHEN v.age > 60 THEN '60+'
          ELSE 'Other'
        END as age_range,
        COUNT(*) as count
      $baseQuery
      GROUP BY age_range
      ORDER BY age_range
    ''', args);

    Map<String, int> ageGroups = {};
    for (var row in ageGroupsResult) {
      ageGroups[row['age_range'] as String] = row['count'] as int;
    }

    // Get main categories from categorized table
    String additionalWhere = '';
    if (baseQuery.contains('AND')) {
      additionalWhere = baseQuery.substring(baseQuery.indexOf('AND'));
    }
    List<Map<String, dynamic>> mainCategoriesResult = await db.rawQuery('''
      SELECT COALESCE(c.Mname, 'Unrecognized') as main_category, COUNT(*) as count
      FROM categorized c
      INNER JOIN voter v ON c.voter_no = v.voter_no
      LEFT JOIN election_booth eb ON v.booth_id = eb.id
      LEFT JOIN ward w ON eb.ward_id = w.id
      LEFT JOIN municipality m ON w.municipality_id = m.id
      LEFT JOIN district d ON m.district_id = d.id
      LEFT JOIN province p ON d.province_id = p.id
      WHERE 1=1
      $additionalWhere
      GROUP BY main_category
      ORDER BY count DESC
    ''', args);

    Map<String, int> mainCategories = {};
    for (var row in mainCategoriesResult) {
      mainCategories[row['main_category'] as String] = row['count'] as int;
    }

    // Get grouped data with detailed stats
    // Map<String, Map<String, dynamic>> groupedData = {};
    // if (groupBy != null) {
    //   String groupByColumn;
    //   String groupByJoin = '';
    //   String groupByWhere = '';

    //   switch (groupBy) {
    //     case 'province':
    //       groupByColumn = 'p.name';
    //       groupByJoin = 'LEFT JOIN province p ON d.province_id = p.id';
    //       groupByWhere = 'p.id IS NOT NULL';
    //       break;
    //     case 'district':
    //       groupByColumn = 'd.name';
    //       groupByJoin = 'LEFT JOIN district d ON m.district_id = d.id';
    //       groupByWhere = 'd.id IS NOT NULL';
    //       break;
    //     case 'municipality':
    //       groupByColumn = 'm.name';
    //       groupByJoin = 'LEFT JOIN municipality m ON w.municipality_id = m.id';
    //       groupByWhere = 'm.id IS NOT NULL';
    //       break;
    //     case 'ward':
    //       groupByColumn = "CONCAT(m.name, ' Ward ', w.ward_no)";
    //       groupByJoin = 'LEFT JOIN municipality m ON w.municipality_id = m.id';
    //       groupByWhere = 'w.id IS NOT NULL';
    //       break;
    //     case 'booth':
    //       groupByColumn = 'eb.booth_name';
    //       groupByWhere = 'eb.id IS NOT NULL';
    //       break;
    //     default:
    //       groupByColumn = 'p.name';
    //       groupByJoin = 'LEFT JOIN province p ON d.province_id = p.id';
    //       groupByWhere = 'p.id IS NOT NULL';
    //   }

    //   // Build query for grouped stats
    //   String groupQuery =
    //       '''
    //     SELECT $groupByColumn as name, COUNT(v.id) as count,
    //            SUM(CASE WHEN LOWER(v.gender) = 'male' OR LOWER(v.gender) = 'm' THEN 1 ELSE 0 END) as male_count,
    //            SUM(CASE WHEN LOWER(v.gender) = 'female' OR LOWER(v.gender) = 'f' THEN 1 ELSE 0 END) as female_count,
    //            AVG(v.age) as avg_age
    //     $baseQuery
    //     ${groupByWhere.isNotEmpty ? 'AND $groupByWhere' : ''}
    //     GROUP BY $groupByColumn
    //     ORDER BY count DESC
    //   ''';

    //   List<Map<String, dynamic>> groupedResult = await db.rawQuery(
    //     groupQuery,
    //     args,
    //   );

    //   // For each group, get age groups and main categories
    //   for (var row in groupedResult) {
    //     String groupName = row['name'] as String;
    //     int groupCount = row['count'] as int;

    //     // Build proper filter condition for this group
    //     String groupFilter = '';
    //     List<dynamic> groupArgs = [...args];

    //     switch (groupBy) {
    //       case 'province':
    //         groupFilter = 'AND p.name = ?';
    //         groupArgs.add(groupName);
    //         break;
    //       case 'district':
    //         groupFilter = 'AND d.name = ?';
    //         groupArgs.add(groupName);
    //         break;
    //       case 'municipality':
    //         groupFilter = 'AND m.name = ?';
    //         groupArgs.add(groupName);
    //         break;
    //       case 'ward':
    //         // Parse "Municipality Ward X" format
    //         final parts = groupName.split(' Ward ');
    //         if (parts.length == 2) {
    //           groupFilter = 'AND m.name = ? AND w.ward_no = ?';
    //           groupArgs.add(parts[0]); // municipality name
    //           groupArgs.add(int.parse(parts[1])); // ward number
    //         }
    //         break;
    //       case 'booth':
    //         groupFilter = 'AND eb.booth_name = ?';
    //         groupArgs.add(groupName);
    //         break;
    //     }

    //     // Get age groups for this group - directly from voter table
    //     String ageGroupQuery =
    //         '''
    //       SELECT
    //         CASE
    //           WHEN v.age BETWEEN 18 AND 30 THEN '18-30'
    //           WHEN v.age BETWEEN 31 AND 45 THEN '31-45'
    //           WHEN v.age BETWEEN 46 AND 60 THEN '46-60'
    //           WHEN v.age > 60 THEN '60+'
    //           ELSE 'Other'
    //         END as age_range,
    //         COUNT(*) as count
    //       $baseQuery
    //       $groupFilter
    //       GROUP BY age_range
    //       ORDER BY age_range
    //     ''';

    //     List<Map<String, dynamic>> ageGroupResult = await db.rawQuery(
    //       ageGroupQuery,
    //       groupArgs,
    //     );
    //     Map<String, int> ageGroups = {};
    //     for (var ageRow in ageGroupResult) {
    //       ageGroups[ageRow['age_range'] as String] = ageRow['count'] as int;
    //     }

    //     // Get main categories for this group - from categorized table joined with voter
    //     String categoryQuery =
    //         '''
    //       SELECT COALESCE(c.Mname, 'Unrecognized') as main_category, COUNT(*) as count
    //       FROM categorized c
    //       INNER JOIN voter v ON c.voter_no = v.voter_no
    //       LEFT JOIN election_booth eb ON v.booth_id = eb.id
    //       LEFT JOIN ward w ON eb.ward_id = w.id
    //       LEFT JOIN municipality m ON w.municipality_id = m.id
    //       LEFT JOIN district d ON m.district_id = d.id
    //       LEFT JOIN province p ON d.province_id = p.id
    //       WHERE 1=1
    //       ${baseQuery.contains('WHERE') ? baseQuery.substring(baseQuery.indexOf('WHERE') + 6) : ''}
    //       $groupFilter
    //       GROUP BY main_category
    //       ORDER BY count DESC
    //     ''';

    //     List<Map<String, dynamic>> categoryResult = await db.rawQuery(
    //       categoryQuery,
    //       groupArgs,
    //     );
    //     Map<String, int> mainCategories = {};
    //     for (var catRow in categoryResult) {
    //       mainCategories[catRow['main_category'] as String] =
    //           catRow['count'] as int;
    //     }

    //     groupedData[groupName] = {
    //       'count': groupCount,
    //       'male_count': row['male_count'] as int,
    //       'female_count': row['female_count'] as int,
    //       'avg_age': (row['avg_age'] as num?)?.toDouble() ?? 0.0,
    //       'age_groups': ageGroups,
    //       'main_categories': mainCategories,
    //     };
    //   }
    // }

    // Helper function to get grouped data
    Future<Map<String, dynamic>> getGroupedData(
      String groupByColumn,
      String tableName, {
      String? joinCondition,
      String? additionalWhere,
    }) async {
      String query =
          'SELECT $groupByColumn as name, COUNT(v.id) as count FROM voter v';
      if (joinCondition != null) {
        query += ' $joinCondition';
      }
      query += ' WHERE 1=1';
      if (additionalWhere != null) {
        query += ' AND $additionalWhere';
      }
      query += ' GROUP BY $groupByColumn ORDER BY count DESC';

      List<Map<String, dynamic>> results = await db.rawQuery(query);
      Map<String, dynamic> grouped = {};
      for (var row in results) {
        grouped[row['name'] as String] = row['count'] as int;
      }
      return grouped;
    }

    // Get grouped data
    Map<String, dynamic> byProvince = await getGroupedData(
      'p.name',
      'province',
      joinCondition:
          'LEFT JOIN election_booth eb ON v.booth_id = eb.id LEFT JOIN ward w ON eb.ward_id = w.id LEFT JOIN municipality m ON w.municipality_id = m.id LEFT JOIN district d ON m.district_id = d.id LEFT JOIN province p ON d.province_id = p.id',
    );

    Map<String, dynamic> byDistrict = await getGroupedData(
      'd.name',
      'district',
      joinCondition:
          'LEFT JOIN election_booth eb ON v.booth_id = eb.id LEFT JOIN ward w ON eb.ward_id = w.id LEFT JOIN municipality m ON w.municipality_id = m.id LEFT JOIN district d ON m.district_id = d.id',
    );

    Map<String, dynamic> byMunicipality = await getGroupedData(
      'm.name',
      'municipality',
      joinCondition:
          'LEFT JOIN election_booth eb ON v.booth_id = eb.id LEFT JOIN ward w ON eb.ward_id = w.id LEFT JOIN municipality m ON w.municipality_id = m.id',
    );

    Map<String, dynamic> byWard = await getGroupedData(
      "m.name || ' Ward ' || w.ward_no",
      'ward',
      joinCondition:
          'LEFT JOIN election_booth eb ON v.booth_id = eb.id LEFT JOIN ward w ON eb.ward_id = w.id LEFT JOIN municipality m ON w.municipality_id = m.id',
    );

    Map<String, dynamic> byBooth = await getGroupedData(
      'eb.booth_name',
      'election_booth',
      joinCondition: 'LEFT JOIN election_booth eb ON v.booth_id = eb.id',
    );

    return {
      'total_voters': totalVoters,
      'avg_age': avgAge,
      'male_count': maleCount,
      'female_count': femaleCount,
      'booth_count': boothCount,
      'ward_count': wardCount,
      'age_groups': ageGroups,
      'main_categories': mainCategories,
      // 'grouped_data': groupedData,
      'by_province': byProvince,
      'by_district': byDistrict,
      'by_municipality': byMunicipality,
      'by_ward': byWard,
      'by_booth': byBooth,
    };
  }

  Future<Map<String, dynamic>> getGenderStats() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT gender, COUNT(*) as count
      FROM voter
      GROUP BY gender
    ''');
    return {'genderStats': result};
  }

  // Additional search method for voter_search_provider
  Future<List<Voter>> searchVotersForProvider({
    required String query,
    required SearchField field,
    required SearchMatchMode mode,
    int? districtId,
    int? municipalityId,
    int? wardId,
    int? boothId,
    int? limit,
  }) async {
    Database db = await database;

    // If searching by voter ID, use simple query
    if (field == SearchField.voterId) {
      String sql = '''
        SELECT v.*, eb.booth_code, eb.booth_name, w.ward_no, m.name as municipality_name,
               d.name as district_name, p.name as province_name
        FROM voter v
        LEFT JOIN election_booth eb ON v.booth_id = eb.id
        LEFT JOIN ward w ON eb.ward_id = w.id
        LEFT JOIN municipality m ON w.municipality_id = m.id
        LEFT JOIN district d ON m.district_id = d.id
        LEFT JOIN province p ON d.province_id = p.id
        WHERE v.voter_no LIKE ?
      ''';

      List<dynamic> args = [
        mode == SearchMatchMode.startsWith ? '$query%' : '%$query%',
      ];

      if (districtId != null) {
        sql += ' AND d.id = ?';
        args.add(districtId);
      }

      if (municipalityId != null) {
        sql += ' AND m.id = ?';
        args.add(municipalityId);
      }

      if (wardId != null) {
        sql += ' AND w.id = ?';
        args.add(wardId);
      }

      if (boothId != null) {
        sql += ' AND eb.id = ?';
        args.add(boothId);
      }

      if (limit != null) {
        sql += ' LIMIT ?';
        args.add(limit);
      }

      final rows = await db.rawQuery(sql, args);
      return rows.map((row) => Voter.fromMap(row)).toList();
    }

    // For name search, use simple search
    String sql = '''
      SELECT v.*, eb.booth_code, eb.booth_name, w.ward_no, m.name as municipality_name,
             d.name as district_name, p.name as province_name
      FROM voter v
      LEFT JOIN election_booth eb ON v.booth_id = eb.id
      LEFT JOIN ward w ON eb.ward_id = w.id
      LEFT JOIN municipality m ON w.municipality_id = m.id
      LEFT JOIN district d ON m.district_id = d.id
      LEFT JOIN province p ON d.province_id = p.id
      WHERE v.name LIKE ?
    ''';

    List<dynamic> args = [
      mode == SearchMatchMode.startsWith ? '$query%' : '%$query%',
    ];

    // Add location filters
    if (districtId != null) {
      sql += ' AND d.id = ?';
      args.add(districtId);
    }

    if (municipalityId != null) {
      sql += ' AND m.id = ?';
      args.add(municipalityId);
    }

    if (wardId != null) {
      sql += ' AND w.id = ?';
      args.add(wardId);
    }

    if (boothId != null) {
      sql += ' AND eb.id = ?';
      args.add(boothId);
    }

    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }

    final rows = await db.rawQuery(sql, args);
    return rows.map((row) => Voter.fromMap(row)).toList();
  }

  // Update voter method
  Future<int> updateVoter(int id, Map<String, dynamic> data) async {
    Database db = await database;
    return await db.update('voter', data, where: 'id = ?', whereArgs: [id]);
  }

  // Insert or update categorized method
  Future<int> insertOrUpdateCategorized(
    String voterNo,
    Map<String, dynamic> data,
  ) async {
    Database db = await database;

    // Check if record exists
    List<Map<String, dynamic>> existing = await db.query(
      'categorized',
      where: 'voter_no = ?',
      whereArgs: [voterNo],
    );

    if (existing.isNotEmpty) {
      // Update existing record
      return await db.update(
        'categorized',
        data,
        where: 'voter_no = ?',
        whereArgs: [voterNo],
      );
    } else {
      // Insert new record
      return await db.insert('categorized', data);
    }
  }

  // Update voterdetails method
  Future<int> updateVoterDetails(int voterId, Map<String, dynamic> data) async {
    Database db = await database;

    // Check if record exists
    List<Map<String, dynamic>> existing = await db.query(
      'voterdetails',
      where: 'voterid = ?',
      whereArgs: [voterId],
    );

    if (existing.isNotEmpty) {
      // Update existing record
      return await db.update(
        'voterdetails',
        data,
        where: 'voterid = ?',
        whereArgs: [voterId],
      );
    } else {
      // Insert new record, need name from voter
      final voter = await getVoter(voterId);
      if (voter != null) {
        final insertData = {
          'voterid': voterId,
          'name': voter['name_np'],
          'phone': data['phone'] ?? '',
          'social_media': '',
          'description': data['description'] ?? '',
        };
        return await db.insert('voterdetails', insertData);
      } else {
        return 0;
      }
    }
  }
}
