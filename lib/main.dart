import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/database_provider.dart'; // ← add this
import 'providers/voter_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/location_repo_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: force DB init before app starts
  // (not strictly needed if you use databaseInitializedProvider in UI)
  // await DatabaseHelper.instance.database;

  runApp(const ProviderScope(child: VoterListApp()));
}

class VoterListApp extends ConsumerWidget {
  const VoterListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch DB init if you want to show splash until ready
    final dbInitAsync = ref.watch(databaseInitializedProvider);
    return MaterialApp(
      title: 'Voter List Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: dbInitAsync.when(
        data: (_) => const HomeScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('DB Error: $err'))),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
