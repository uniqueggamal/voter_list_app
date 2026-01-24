import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tag.dart';

class TagsDatabaseHelper {
  static final TagsDatabaseHelper _instance = TagsDatabaseHelper._internal();
  static Database? _database;

  factory TagsDatabaseHelper() => _instance;

  TagsDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'voter_tags.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE voter_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voter_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE,
        UNIQUE(voter_id, tag_id)
      )
    ''');
  }

  // Tag methods
  Future<List<Tag>> getTags() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('tags');
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  Future<int> insertTag(Tag tag) async {
    Database db = await database;
    return await db.insert('tags', tag.toMap());
  }

  Future<int> updateTag(Tag tag) async {
    Database db = await database;
    return await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<int> deleteTag(int id) async {
    Database db = await database;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // Voter Tag methods
  Future<List<int>> getTagIdsForVoter(int voterId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'voter_tags',
      where: 'voter_id = ?',
      whereArgs: [voterId],
    );
    return maps.map((map) => map['tag_id'] as int).toList();
  }

  Future<List<Tag>> getTagsForVoter(int voterId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT t.* FROM tags t
      INNER JOIN voter_tags vt ON t.id = vt.tag_id
      WHERE vt.voter_id = ?
    ''',
      [voterId],
    );
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  Future<int> addTagToVoter(int voterId, int tagId) async {
    Database db = await database;
    return await db.insert('voter_tags', {
      'voter_id': voterId,
      'tag_id': tagId,
    });
  }

  Future<int> removeTagFromVoter(int voterId, int tagId) async {
    Database db = await database;
    return await db.delete(
      'voter_tags',
      where: 'voter_id = ? AND tag_id = ?',
      whereArgs: [voterId, tagId],
    );
  }

  Future<int> removeAllTagsFromVoter(int voterId) async {
    Database db = await database;
    return await db.delete(
      'voter_tags',
      where: 'voter_id = ?',
      whereArgs: [voterId],
    );
  }
}
