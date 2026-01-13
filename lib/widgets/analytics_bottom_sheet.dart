import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voter_provider.dart';

class AnalyticsBottomSheet extends ConsumerStatefulWidget {
  const AnalyticsBottomSheet({super.key});

  @override
  ConsumerState<AnalyticsBottomSheet> createState() =>
      _AnalyticsBottomSheetState();
}

class _AnalyticsBottomSheetState extends ConsumerState<AnalyticsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Map<String, Animation<double>> _animations;
  bool _showPercentages = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animations = {};
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String formatNumber(double value, {int fraction = 0}) {
    return fraction > 0
        ? value.toStringAsFixed(fraction)
        : value.toStringAsFixed(0);
  }

  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  String _getDisplayValue(double value, double total, bool showPercentages) {
    if (showPercentages && total > 0) {
      return '${(value / total * 100).toStringAsFixed(1)}%';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  Widget _buildAnimatedSummaryItem(
    String label,
    Animation<double> animation,
    IconData icon,
    Color color, {
    int fraction = 0,
    bool showPercentage = false,
    double? totalForPercentage,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        String displayValue;
        if (showPercentage &&
            totalForPercentage != null &&
            totalForPercentage > 0) {
          displayValue = formatPercentage(value / totalForPercentage * 100);
        } else {
          displayValue = formatNumber(value, fraction: fraction);
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgeGroups(Map<String, dynamic> ageGroups) {
    final ageLabels = ['18-25', '26-35', '36-45', '46-60', '60+'];
    final values = ageLabels
        .map((label) => ((ageGroups[label] ?? 0) as num).toDouble())
        .toList();
    double total = 0.0;
    for (final value in values) {
      total += value;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Age Groups',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: ageLabels.map((label) {
              final value = ((ageGroups[label] ?? 0) as num).toDouble();
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _getDisplayValue(value, total, _showPercentages),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDistribution(Map<String, dynamic> analyticsData) {
    final summary = analyticsData['summary'] as Map<String, dynamic>? ?? {};
    final gender = summary['gender'] as Map<String, dynamic>? ?? {};
    final maleCount = ((gender['male'] as Map?)?['count'] ?? 0).toDouble();
    final femaleCount = ((gender['female'] as Map?)?['count'] ?? 0).toDouble();
    final total = maleCount + femaleCount;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Gender Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _getDisplayValue(maleCount, total, _showPercentages),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text('Male', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _getDisplayValue(femaleCount, total, _showPercentages),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const Text('Female', style: TextStyle(color: Colors.pink)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: analyticsAsync.when(
            data: (data) => _buildContent(data, scrollController),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load analytics: $e'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(analyticsDataProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    Map<String, dynamic> analyticsData,
    ScrollController scrollController,
  ) {
    final summary = analyticsData['summary'] as Map<String, dynamic>? ?? {};
    final gender = summary['gender'] as Map<String, dynamic>? ?? {};
    final totalGender =
        ((gender['male'] as Map?)?['count'] ?? 0).toDouble() +
        ((gender['female'] as Map?)?['count'] ?? 0).toDouble();

    // Initialize animations with actual data
    if (_animations.isEmpty) {
      _animations = {
        'total_voters':
            Tween<double>(
              begin: 0,
              end: (summary['total_voters'] ?? 0).toDouble(),
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
        'avg_age':
            Tween<double>(
              begin: 0,
              end: (summary['avg_age'] ?? 0).toDouble(),
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
        'male_count':
            Tween<double>(
              begin: 0,
              end: ((gender['male'] as Map?)?['count'] ?? 0).toDouble(),
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
        'female_count':
            Tween<double>(
              begin: 0,
              end: ((gender['female'] as Map?)?['count'] ?? 0).toDouble(),
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
      };
      _animationController.forward();
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title and Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Voter Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(_showPercentages ? Icons.percent : Icons.tag),
                onPressed: () =>
                    setState(() => _showPercentages = !_showPercentages),
                tooltip: _showPercentages ? 'Show Numbers' : 'Show Percentages',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildAnimatedSummaryItem(
                  'Total Voters',
                  _animations['total_voters']!,
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnimatedSummaryItem(
                  'Avg Age',
                  _animations['avg_age']!,
                  Icons.calendar_today,
                  Colors.green,
                  fraction: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnimatedSummaryItem(
                  'Male',
                  _animations['male_count']!,
                  Icons.male,
                  Colors.blue[700]!,
                  showPercentage: _showPercentages,
                  totalForPercentage: totalGender,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnimatedSummaryItem(
                  'Female',
                  _animations['female_count']!,
                  Icons.female,
                  Colors.pink[700]!,
                  showPercentage: _showPercentages,
                  totalForPercentage: totalGender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gender Distribution
          _buildGenderDistribution(analyticsData),
          const SizedBox(height: 16),

          // Age Groups
          _buildAgeGroups(summary['age_groups'] ?? {}),

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
