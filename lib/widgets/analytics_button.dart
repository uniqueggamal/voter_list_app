import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voter_provider.dart';
import 'analytics_bottom_sheet.dart';

class AnalyticsButtonWidget extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const AnalyticsButtonWidget({super.key, required this.parentContext});

  @override
  ConsumerState<AnalyticsButtonWidget> createState() =>
      _AnalyticsButtonWidgetState();
}

class _AnalyticsButtonWidgetState extends ConsumerState<AnalyticsButtonWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _showAnalytics(context),
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.analytics),
      label: _isLoading ? const Text('Loading...') : const Text('Analytics'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showAnalytics(BuildContext context) async {
    debugPrint('AnalyticsButton: _showAnalytics called');
    if (_isLoading) {
      debugPrint('AnalyticsButton: Already loading, returning');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('AnalyticsButton: Set loading to true');

    final provider = ref.read(voterProvider.notifier);

    try {
      // Load analytics data into state
      await provider.loadAnalyticsData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Analytics query timed out');
        },
      );

      if (!mounted) {
        debugPrint(
          'AnalyticsButton: Widget not mounted after loadAnalyticsData',
        );
        return;
      }

      if (!widget.parentContext.mounted) {
        debugPrint('AnalyticsButton: Parent context not mounted');
        return;
      }

      // Show the analytics bottom sheet (data will be displayed reactively)
      debugPrint('AnalyticsButton: Showing analytics bottom sheet');
      showModalBottomSheet(
        context: widget.parentContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AnalyticsBottomSheet(),
      );
    } catch (e, st) {
      debugPrint('Analytics error: $e\n$st');
      if (!widget.parentContext.mounted) return;
      ScaffoldMessenger.of(
        widget.parentContext,
      ).showSnackBar(SnackBar(content: Text('Failed to load analytics: $e')));
    } finally {
      if (mounted) {
        debugPrint('AnalyticsButton: Setting loading to false');
        setState(() => _isLoading = false);
      }
    }
  }
}
