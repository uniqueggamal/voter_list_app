import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/voter_provider.dart';
import '../providers/filter_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPercentages = false;
  String _groupBy = 'province';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final totalCountAsync = ref.watch(totalVoterCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export as Excel',
            onPressed: _exportAsExcel,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overall'),
            Tab(text: 'Grouping'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overall Analytics Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: analyticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (data) => _buildOverallAnalytics(data, totalCountAsync),
            ),
          ),
          // Grouping Analytics Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: analyticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (data) => _buildGroupingAnalytics(data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAnalytics(
    Map<String, dynamic> data,
    AsyncValue<int> totalCountAsync,
  ) {
    final totalVoters = totalCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final maleCount = data['male_count'] ?? 0;
    final femaleCount = data['female_count'] ?? 0;
    final avgAge = data['avg_age'] ?? 0.0;
    final ageGroups = data['age_groups'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Total Voters', totalVoters.toString()),
                    _buildStatCard('Average Age', avgAge.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildGenderRatio(maleCount, femaleCount)],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Age Groups Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Age Groups',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(
                        _showPercentages ? Icons.percent : Icons.numbers,
                      ),
                      label: Text(_showPercentages ? 'Percent' : 'Count'),
                      onPressed: () =>
                          setState(() => _showPercentages = !_showPercentages),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _showPercentages
                          ? 100
                          : (ageGroups.values.isEmpty
                                ? 0
                                : ageGroups.values
                                      .reduce((a, b) => a > b ? a : b)
                                      .toDouble()),
                      barGroups: _buildAgeGroupBars(ageGroups),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const ageRanges = [
                                '18-30',
                                '31-45',
                                '46-60',
                                '60+',
                              ];
                              if (value.toInt() < ageRanges.length) {
                                return Text(
                                  ageRanges[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _showPercentages
                                    ? '${value.toInt()}%'
                                    : value.toInt().toString(),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupingAnalytics(Map<String, dynamic> data) {
    final groupedData = data['grouped_data'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group By Dropdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _groupBy,
              decoration: const InputDecoration(labelText: 'Group By'),
              items: const [
                DropdownMenuItem(value: 'province', child: Text('Province')),
                DropdownMenuItem(value: 'district', child: Text('District')),
                DropdownMenuItem(
                  value: 'municipality',
                  child: Text('Municipality'),
                ),
                DropdownMenuItem(value: 'ward', child: Text('Ward')),
                DropdownMenuItem(value: 'booth', child: Text('Booth')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _groupBy = value);
                  // Trigger reload with new groupBy
                  ref.read(voterProvider.notifier).state = ref
                      .read(voterProvider)
                      .copyWith(groupBy: value);
                  ref.invalidate(analyticsDataProvider);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Grouped Stats
        ...groupedData.entries.map((entry) {
          final groupName = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          final count = stats['count'] ?? 0;
          final maleCount = stats['male_count'] ?? 0;
          final femaleCount = stats['female_count'] ?? 0;
          final avgAge = stats['avg_age'] ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Total', count.toString()),
                      _buildStatCard('Avg Age', avgAge.toStringAsFixed(1)),
                      _buildGenderRatio(maleCount, femaleCount),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildGenderRatio(int maleCount, int femaleCount) {
    final total = maleCount + femaleCount;
    final malePercent = total > 0 ? (maleCount / total * 100).round() : 0;
    final femalePercent = total > 0 ? (femaleCount / total * 100).round() : 0;

    return Row(
      children: [
        Icon(Icons.male, color: Colors.blue),
        Text('$maleCount ($malePercent%)'),
        const SizedBox(width: 16),
        Icon(Icons.female, color: Colors.pink),
        Text('$femaleCount ($femalePercent%)'),
      ],
    );
  }

  List<BarChartGroupData> _buildAgeGroupBars(Map<String, dynamic> ageGroups) {
    const ageRanges = ['18-30', '31-45', '46-60', '60+'];
    final bars = <BarChartGroupData>[];

    for (int i = 0; i < ageRanges.length; i++) {
      final range = ageRanges[i];
      final count = ageGroups[range] ?? 0;
      final value = _showPercentages && ageGroups.values.isNotEmpty
          ? (count / ageGroups.values.reduce((a, b) => a + b) * 100)
          : count.toDouble();

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: value, color: Colors.blue, width: 20)],
        ),
      );
    }

    return bars;
  }

  Future<void> _exportAsExcel() async {
    // TODO: Implement Excel export for analytics data
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel export coming soon...')),
      );
    }
  }
}
