import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CleanupHelper {
  static final CleanupHelper _instance = CleanupHelper._internal();
  static const String _cleanupFlagFile = 'app_active.flag';

  factory CleanupHelper() => _instance;

  CleanupHelper._internal();

  /// Creates a flag file to indicate the app is currently active
  Future<void> markAppActive() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final flagFile = File(join(directory.path, _cleanupFlagFile));
      await flagFile.writeAsString(DateTime.now().toIso8601String());
      debugPrint('App active flag created');
    } catch (e) {
      debugPrint('Failed to create active flag: $e');
    }
  }

  /// Removes the active flag file
  Future<void> markAppInactive() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final flagFile = File(join(directory.path, _cleanupFlagFile));
      if (await flagFile.exists()) {
        await flagFile.delete();
        debugPrint('App inactive flag removed');
      }
    } catch (e) {
      debugPrint('Failed to remove active flag: $e');
    }
  }

  /// Cleans up database files if no active flag exists (indicating app was previously uninstalled)
  Future<void> cleanupOrphanedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final flagFile = File(join(directory.path, _cleanupFlagFile));

      // If flag file doesn't exist, app was likely uninstalled and files are orphaned
      if (!await flagFile.exists()) {
        debugPrint(
          'No active flag found - cleaning up orphaned database files',
        );

        // List of database files to clean up
        final dbFiles = [
          'voter_list_readable.db',
          'voter_tags.db',
          'voter_additional_details.db',
          'notes_list.db',
        ];

        for (final dbFile in dbFiles) {
          final file = File(join(directory.path, dbFile));
          if (await file.exists()) {
            await file.delete();
            debugPrint('Cleaned up orphaned file: $dbFile');
          }
        }

        // Clean up any exported files (PDFs, Excel files)
        final exportedFiles = await directory.list().where((entity) {
          return entity is File &&
              (entity.path.endsWith('.pdf') ||
                  entity.path.endsWith('.xlsx') ||
                  entity.path.endsWith('.xls'));
        }).toList();

        for (final file in exportedFiles) {
          await file.delete();
          debugPrint('Cleaned up exported file: ${basename(file.path)}');
        }
      } else {
        debugPrint('Active flag found - app was not uninstalled');
      }

      // Always create/update the active flag after cleanup check
      await markAppActive();
    } catch (e) {
      debugPrint('Cleanup failed: $e');
    }
  }
}
