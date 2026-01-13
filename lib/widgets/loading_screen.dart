import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voter_provider.dart';

/// Global loading overlay for initial voter data
class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voterState = ref.watch(voterProvider);

    // Show loading screen if voters are loading and list is empty
    if (voterState.isLoading && voterState.voters.isEmpty) {
      return Container(
        color: Colors.white.withOpacity(0.95),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Loading voter data...', style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              Text(
                'कृपया पर्खनुहोस्...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Show error screen if there's a loading error
    if (voterState.loadingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error loading voters: ${voterState.loadingError}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(voterProvider.notifier).loadVoters(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // No loading or error, show nothing
    return const SizedBox.shrink();
  }
}
