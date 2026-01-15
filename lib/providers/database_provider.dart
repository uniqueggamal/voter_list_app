import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/database_helper.dart'; // adjust path if needed

/// Provides direct access to the DatabaseHelper singleton
final dbHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

/// Triggers database initialization and signals when it's ready
/// Use this in main.dart or a splash screen to wait for DB before showing UI
final databaseInitializedProvider = FutureProvider<bool>((ref) async {
  final dbHelper = ref.watch(dbHelperProvider);
  await dbHelper.database; // this opens/creates/copies the DB if needed
  return true;
});

/// Provides gender statistics (total, male, female) from the voter table
/// Auto-refreshes if DB changes (though unlikely in this offline app)
final statsProvider = FutureProvider<Map<String, int>>((ref) async {
  final dbHelper = ref.watch(dbHelperProvider);
  return dbHelper.getGenderStats();
});
