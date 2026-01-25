import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'helpers/database_helper.dart';
import 'helpers/cleanup_helper.dart';
import 'providers/database_provider.dart'; // ← add this
import 'providers/voter_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/location_repo_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean up orphaned database files from previous installations
  await CleanupHelper().cleanupOrphanedFiles();

  // Safe first-launch check: open DB to trigger any migration
  await DatabaseHelper.instance.database;
  debugPrint('DB opened successfully on first launch');

  runApp(const ProviderScope(child: VoterListApp()));
}

class VoterListApp extends ConsumerStatefulWidget {
  const VoterListApp({super.key});

  @override
  ConsumerState<VoterListApp> createState() => _VoterListAppState();
}

class _VoterListAppState extends ConsumerState<VoterListApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      // Mark app as inactive when it's being terminated or paused
      CleanupHelper().markAppInactive();
    } else if (state == AppLifecycleState.resumed) {
      // Mark app as active when resumed
      CleanupHelper().markAppActive();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        data: (_) => FutureBuilder(
          future: DatabaseHelper.instance.ensureNormalizedTable(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            } else {
              return const HomeScreen();
            }
          },
        ),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('DB Error: $err'))),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
