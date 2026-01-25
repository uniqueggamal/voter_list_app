import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../helpers/tags_database_helper.dart';
import '../models/tag.dart';

class ImportService {
  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  Future<void> importExcelFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      if (!await file.exists()) {
        _showErrorDialog(context, 'Selected file does not exist.');
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _showErrorDialog(context, 'Selected file is empty.');
        return;
      }

      final excel = Excel.decodeBytes(bytes);
      if (excel == null) {
        _showErrorDialog(
          context,
          'Failed to decode Excel file. Invalid format.',
        );
        return;
      }

      if (excel.tables.isEmpty) {
        _showErrorDialog(context, 'Excel file contains no sheets.');
        return;
      }

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        _showErrorDialog(context, 'Excel sheet is empty or invalid.');
        return;
      }

      // 1. Map headers to indices (Handles lowercase and spaces)
      if (sheet.rows.isEmpty) {
        _showErrorDialog(context, 'Excel sheet has no rows.');
        return;
      }

      final headerRow = sheet.rows.first;
      if (headerRow.isEmpty) {
        _showErrorDialog(context, 'Excel sheet has no header columns.');
        return;
      }

      final columnMap = <String, int>{};
      for (int i = 0; i < headerRow.length; i++) {
        final rawHeader = headerRow[i]?.value?.toString().trim() ?? '';
        // Map display names to internal keys
        final header = _mapHeaderToKey(rawHeader);
        columnMap[header] = i;
      }

      if (!columnMap.containsKey('voter_no')) {
        _showErrorDialog(
          context,
          'Excel file must contain a "voter_no" column.',
        );
        return;
      }

      int importedCount = 0;
      int errorCount = 0;
      final db = await DatabaseHelper.instance.database;

      // 2. Start Transaction for speed
      await db.transaction((txn) async {
        for (final row in sheet.rows.skip(1)) {
          try {
            // Skip empty rows
            if (row.isEmpty) continue;

            // Check if row has enough columns for voter_no
            final voterNoIndex = columnMap['voter_no']!;
            if (voterNoIndex >= row.length) continue;

            final voterNo = row[voterNoIndex]?.value?.toString().trim() ?? '';
            if (voterNo.isEmpty) continue;

            // Find internal ID for this voter
            final res = await txn.query(
              'voter',
              where: 'voter_no = ?',
              whereArgs: [voterNo],
              limit: 1,
            );
            if (res.isEmpty) {
              errorCount++;
              continue;
            }
            final voterId = res.first['id'] as int;
            final voterName = res.first['name_np'] as String;

            // --- TABLE 1: VOTER (Core Info) ---
            final voterUpdate = <String, dynamic>{};
            if (columnMap.containsKey('name') &&
                columnMap['name']! < row.length)
              voterUpdate['name_np'] = row[columnMap['name']!]?.value
                  ?.toString();
            if (columnMap.containsKey('age') && columnMap['age']! < row.length)
              voterUpdate['age'] = int.tryParse(
                row[columnMap['age']!]?.value?.toString() ?? '',
              );
            if (columnMap.containsKey('parents_name') &&
                columnMap['parents_name']! < row.length)
              voterUpdate['parent_name_np'] = row[columnMap['parents_name']!]
                  ?.value
                  ?.toString();
            if ((columnMap.containsKey('spouse_name') ||
                columnMap.containsKey('spouse_name_np'))) {
              final spouseKey = columnMap.containsKey('spouse_name')
                  ? 'spouse_name'
                  : 'spouse_name_np';
              if (columnMap[spouseKey]! < row.length) {
                voterUpdate['spouse_name_np'] = row[columnMap[spouseKey]!]
                    ?.value
                    ?.toString();
              }
            }

            if (voterUpdate.isNotEmpty) {
              await txn.update(
                'voter',
                voterUpdate,
                where: 'id = ?',
                whereArgs: [voterId],
              );
            }

            // --- TABLE 2: VOTERDETAILS (Phone/Desc) ---
            final detailsUpdate = <String, dynamic>{};
            if (columnMap.containsKey('phone_no'))
              detailsUpdate['phone'] = row[columnMap['phone_no']!]?.value
                  ?.toString();
            if (columnMap.containsKey('description'))
              detailsUpdate['description'] = row[columnMap['description']!]
                  ?.value
                  ?.toString();
            if (columnMap.containsKey('name_en'))
              detailsUpdate['name_en'] = row[columnMap['name_en']!]?.value
                  ?.toString();

            if (detailsUpdate.isNotEmpty) {
              // UPSERT logic for voterdetails
              final existingDetails = await txn.query(
                'voterdetails',
                where: 'voterid = ?',
                whereArgs: [voterId],
              );
              if (existingDetails.isEmpty) {
                detailsUpdate['voterid'] = voterId;
                detailsUpdate['name'] = voterName;
                await txn.insert('voterdetails', detailsUpdate);
              } else {
                await txn.update(
                  'voterdetails',
                  detailsUpdate,
                  where: 'voterid = ?',
                  whereArgs: [voterId],
                );
              }
            }

            // --- TABLE 3: CATEGORIZED (Ethnic Info) ---
            final catUpdate = <String, dynamic>{};
            if (columnMap.containsKey('main_category') &&
                columnMap['main_category']! < row.length)
              catUpdate['Mname'] = row[columnMap['main_category']!]?.value
                  ?.toString();
            if (columnMap.containsKey('sub_category') &&
                columnMap['sub_category']! < row.length)
              catUpdate['Sname'] = row[columnMap['sub_category']!]?.value
                  ?.toString();

            if (catUpdate.isNotEmpty) {
              final existingCat = await txn.query(
                'categorized',
                where: 'voter_no = ?',
                whereArgs: [voterNo],
              );
              if (existingCat.isEmpty) {
                catUpdate['voter_no'] = voterNo;
                catUpdate['name'] = voterName;
                await txn.insert('categorized', catUpdate);
              } else {
                await txn.update(
                  'categorized',
                  catUpdate,
                  where: 'voter_no = ?',
                  whereArgs: [voterNo],
                );
              }
            }

            // --- TABLE 4: VOTER_TAG (Tags) ---
            if (columnMap.containsKey('tags') &&
                columnMap['tags']! < row.length) {
              final tagsString =
                  row[columnMap['tags']!]?.value?.toString()?.trim() ?? '';
              if (tagsString.isNotEmpty) {
                final tagNames = tagsString
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                // Remove existing tags for this voter
                await TagsDatabaseHelper().removeAllTagsFromVoter(voterId);

                // Process each tag
                for (final tagName in tagNames) {
                  // Check if tag exists
                  final existingTags = await TagsDatabaseHelper().getTags();
                  final existingTag = existingTags
                      .where(
                        (tag) =>
                            tag.name.toLowerCase() == tagName.toLowerCase(),
                      )
                      .toList();

                  int tagId;
                  if (existingTag.isNotEmpty) {
                    tagId = existingTag.first.id!;
                  } else {
                    // Create new tag with default color
                    final newTag = Tag(
                      id: 0, // Will be auto-assigned by database
                      name: tagName,
                      color: '#FF6B6B',
                    ); // Default red color
                    tagId = await TagsDatabaseHelper().insertTag(newTag);
                  }

                  // Add tag to voter
                  await TagsDatabaseHelper().addTagToVoter(voterId, tagId);
                }
              }
            }

            importedCount++;
          } catch (e) {
            errorCount++;
          }
        }
      });

      _showSuccessDialog(
        context,
        'Import complete! Updated: $importedCount, Errors: $errorCount',
      );
    } catch (e) {
      _showErrorDialog(context, 'Critical Error: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _mapHeaderToKey(String rawHeader) {
    // Normalize the header: lowercase, trim, replace spaces with underscores
    final normalized = rawHeader.toLowerCase().trim().replaceAll(' ', '_');

    // Map common display names to internal keys
    switch (normalized) {
      case 'voter_no.':
      case 'voter_no':
        return 'voter_no';
      case 'name':
        return 'name';
      case 'name_en':
      case 'name_english':
        return 'name_en';
      case 'last_name':
        return 'last_name';
      case 'age':
        return 'age';
      case 'parents_name':
      case 'parent_name':
        return 'parents_name';
      case 'spouse_name':
        return 'spouse_name';
      case 'province':
        return 'province';
      case 'district':
        return 'district';
      case 'municipality':
        return 'municipality';
      case 'ward_no.':
      case 'ward_no':
        return 'ward_no';
      case 'booth_name':
        return 'booth_name';
      case 'main_category':
        return 'main_category';
      case 'sub_category':
        return 'sub_category';
      case 'tags':
        return 'tags';
      case 'phone':
      case 'phone_no':
        return 'phone_no';
      case 'description':
        return 'description';
      default:
        return normalized; // Fallback to normalized version
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Successful'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
