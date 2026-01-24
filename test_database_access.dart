import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'lib/helpers/database_helper.dart';
import 'lib/models/voter.dart';

void main() async {
  print('Testing database access...');

  try {
    // Initialize database
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    print('Database initialized successfully');

    // Test getting a voter (using ID 1 as example)
    final voterData = await dbHelper.getVoter(1);
    if (voterData != null) {
      print('Voter data retrieved: $voterData');

      final voter = Voter.fromMap(voterData);
      print('Voter object created: ${voter.toString()}');
      print('Main Category: ${voter.mainCategory}');
      print('Sub Category: ${voter.subCategory}');
      print('Province: ${voter.province}');
      print('District: ${voter.district}');
      print('Municipality: ${voter.municipality}');
      print('Booth Name: ${voter.boothName}');
    } else {
      print('No voter data found for ID 1');
    }

    // Test getting voters with categories
    final voters = await dbHelper.getVoters(limit: 5);
    print('Retrieved ${voters.length} voters');
    if (voters.isNotEmpty) {
      final firstVoter = voters.first;
      print('First voter data: $firstVoter');
    }
  } catch (e) {
    print('Error during testing: $e');
  }
}
