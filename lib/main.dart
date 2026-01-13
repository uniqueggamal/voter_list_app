import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/voter_provider.dart';
import 'providers/filter_provider.dart'; // ← important
import 'providers/location_repo_provider.dart'; // ← important for locationRepoProvider
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: VoterListApp()));
}

class VoterListApp extends ConsumerWidget {
  const VoterListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Voter List Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        useMaterial3:
            true, // modern look (optional, remove if you don't like it)
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
