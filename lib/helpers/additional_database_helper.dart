import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AdditionalDatabaseHelper {
  static final AdditionalDatabaseHelper _instance =
      AdditionalDatabaseHelper._internal();
  static Database? _database;

  factory AdditionalDatabaseHelper() => _instance;

  AdditionalDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'voter_additional_details.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE voter_additional_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voter_no TEXT NOT NULL UNIQUE,
        name TEXT,
        english_name TEXT,
        age TEXT,
        gender TEXT,
        parents_name TEXT,
        ward_no TEXT,
        booth_name TEXT,
        municipality TEXT,
        district TEXT,
        province TEXT,
        main_category TEXT,
        sub_category TEXT,
        phone TEXT,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN name TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN english_name TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN age TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN gender TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN parents_name TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN ward_no TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN booth_name TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN municipality TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN district TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN province TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN main_category TEXT',
      );
      await db.execute(
        'ALTER TABLE voter_additional_details ADD COLUMN sub_category TEXT',
      );
    }
  }

  // Insert or update additional details
  Future<int> insertOrUpdateAdditionalDetails(
    String voterNo, {
    String? name,
    String? englishName,
    String? age,
    String? gender,
    String? parentsName,
    String? wardNo,
    String? boothName,
    String? municipality,
    String? district,
    String? province,
    String? mainCategory,
    String? subCategory,
    String? phone,
    String? description,
  }) async {
    Database db = await database;

    // Check if record exists
    List<Map<String, dynamic>> existing = await db.query(
      'voter_additional_details',
      where: 'voter_no = ?',
      whereArgs: [voterNo],
    );

    Map<String, dynamic> data = {
      'voter_no': voterNo,
      'name': name,
      'english_name': englishName,
      'age': age,
      'gender': gender,
      'parents_name': parentsName,
      'ward_no': wardNo,
      'booth_name': boothName,
      'municipality': municipality,
      'district': district,
      'province': province,
      'main_category': mainCategory,
      'sub_category': subCategory,
      'phone': phone,
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      // Update
      return await db.update(
        'voter_additional_details',
        data,
        where: 'voter_no = ?',
        whereArgs: [voterNo],
      );
    } else {
      // Insert
      data['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('voter_additional_details', data);
    }
  }

  // Get additional details by voter_no
  Future<Map<String, dynamic>?> getAdditionalDetails(String voterNo) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'voter_additional_details',
      where: 'voter_no = ?',
      whereArgs: [voterNo],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Get all additional details
  Future<List<Map<String, dynamic>>> getAllAdditionalDetails() async {
    Database db = await database;
    return await db.query('voter_additional_details');
  }

  // Delete additional details
  Future<int> deleteAdditionalDetails(String voterNo) async {
    Database db = await database;
    return await db.delete(
      'voter_additional_details',
      where: 'voter_no = ?',
      whereArgs: [voterNo],
    );
  }
}
