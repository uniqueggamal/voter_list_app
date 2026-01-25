import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
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
  // String _groupBy = 'province';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
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
            // Tab(text: 'Grouping'),
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
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Processing analytics...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (data) => _buildOverallAnalytics(data, totalCountAsync),
            ),
          ),
          // Grouping Analytics Tab
          /*
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: analyticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (data) => _buildGroupingAnalytics(data),
            ),
          ),
          */
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
    final ageGroups =
        (data['age_groups'] as Map<String, dynamic>?)?.map<String, int>(
          (k, v) => MapEntry(k, v as int),
        ) ??
        <String, int>{};
    final mainCategories =
        (data['main_categories'] as Map<String, dynamic>?)?.map<String, int>(
          (k, v) => MapEntry(k, v as int),
        ) ??
        <String, int>{};

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
                const Text(
                  'Age Group Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildAgeGroupsDonut(ageGroups, totalVoters),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Main Ethnic Categories Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Main Ethnic Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildMainCategoriesDonut(mainCategories, totalVoters),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /*
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

        // Grouped Stats with Expandable Cards
        ...groupedData.entries.map((entry) {
          final groupName = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          final count = stats['count'] ?? 0;
          final maleCount = stats['male_count'] ?? 0;
          final femaleCount = stats['female_count'] ?? 0;
          final avgAge = stats['avg_age'] ?? 0.0;
          final ageGroups =
              (stats['age_groups'] as Map<String, dynamic>?)?.map<String, int>(
                (k, v) => MapEntry(k, v as int),
              ) ??
              <String, int>{};
          final mainCategories =
              (stats['main_categories'] as Map<String, dynamic>?)
                  ?.map<String, int>((k, v) => MapEntry(k, v as int)) ??
              <String, int>{};

          return _buildExpandableGroupCard(
            groupName: groupName,
            count: count,
            maleCount: maleCount,
            femaleCount: femaleCount,
            avgAge: avgAge,
            ageGroups: ageGroups,
            mainCategories: mainCategories,
          );
        }),
      ],
    );
  }
  */

  /*
  Widget _buildExpandableGroupCard({
    required String groupName,
    required int count,
    required int maleCount,
    required int femaleCount,
    required double avgAge,
    required Map<String, int> ageGroups,
    required Map<String, int> mainCategories,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          groupName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Total', count.toString()),
              _buildStatCard('Avg Age', avgAge.toStringAsFixed(1)),
              _buildGenderRatio(maleCount, femaleCount),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Age Groups Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Age Group Distribution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAgeGroupsDonut(ageGroups, count),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Main Ethnic Categories Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Main Ethnic Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMainCategoriesDonut(mainCategories, count),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  */

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

  List<PieChartSectionData> _buildAgeGroupPieSections(
    Map<String, int> ageGroups,
  ) {
    const ageRanges = ['18-30', '31-45', '46-60', '60+'];
    const colors = [
      Color(0xFF00C4B4), // vibrant teal
      Color(0xFF3B82F6), // deep blue
      Color(0xFFF97316), // warm orange
      Color(0xFF8B5CF6), // soft purple
    ];

    final total = ageGroups.values.fold<int>(0, (sum, value) => sum + value);
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < ageRanges.length; i++) {
      final range = ageRanges[i];
      final count = ageGroups[range] ?? 0;
      final percent = total > 0 ? (count / total * 100).round() : 0;

      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: colors[i],
          title: '$percent%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
          badgeWidget: Text(
            range,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    return sections;
  }

  Widget _buildAgeGroupLegend(Map<String, int> ageGroups) {
    const ageRanges = ['18-30', '31-45', '46-60', '60+'];
    const colors = [
      Color(0xFF00C4B4), // vibrant teal
      Color(0xFF3B82F6), // deep blue
      Color(0xFFF97316), // warm orange
      Color(0xFF8B5CF6), // soft purple
    ];

    final total = ageGroups.values.fold<int>(0, (sum, value) => sum + value);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(ageRanges.length, (index) {
        final range = ageRanges[index];
        final count = ageGroups[range] ?? 0;
        final percent = total > 0 ? (count / total * 100).round() : 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 16, color: colors[index]),
            const SizedBox(width: 8),
            Text(
              '$range     $count voters ($percent%)',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        );
      }),
    );
  }

  List<PieChartSectionData> _buildMainCategoriesPieSections(
    Map<String, int> mainCategories,
    int totalVoters,
  ) {
    final sortedCategories = mainCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const colors = [
      Color(0xFF6366F1), // indigo
      Color(0xFF8B5CF6), // violet
      Color(0xFFD946EF), // fuchsia
      Color(0xFFEC4899), // pink
      Color(0xFFF43F5E), // rose
      Color(0xFFEA580C), // orange
      Color(0xFFF59E0B), // amber
      Color(0xFF84CC16), // lime
      Color(0xFF10B981), // emerald
      Color(0xFF06B6D4), // cyan
    ];

    final total = mainCategories.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final category = entry.key;
      final count = entry.value;
      final percent = total > 0 ? (count / total * 100).round() : 0;
      final displayName = category.length > 14
          ? '${category.substring(0, 11)}...'
          : category;

      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: colors[i % colors.length],
          title: '$percent%\n$displayName',
          radius: 68,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
          titlePositionPercentageOffset: 0.58,
        ),
      );
    }

    return sections;
  }

  Widget _buildMainCategoriesLegend(Map<String, int> mainCategories) {
    final sortedCategories = mainCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const colors = [
      Color(0xFF6366F1), // indigo
      Color(0xFF8B5CF6), // violet
      Color(0xFFD946EF), // fuchsia
      Color(0xFFEC4899), // pink
      Color(0xFFF43F5E), // rose
      Color(0xFFEA580C), // orange
      Color(0xFFF59E0B), // amber
      Color(0xFF84CC16), // lime
      Color(0xFF10B981), // emerald
      Color(0xFF06B6D4), // cyan
    ];

    final total = mainCategories.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final displayCategories = sortedCategories.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: displayCategories.map((entry) {
        final index = sortedCategories.indexOf(entry);
        final category = entry.key;
        final count = entry.value;
        final percent = total > 0 ? (count / total * 100).round() : 0;
        final displayName = category.length > 20
            ? '${category.substring(0, 17)}...'
            : category;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$displayName: $count voters ($percent%)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgeGroupsDonut(Map<String, int> ageGroups, int totalVoters) {
    if (ageGroups.isEmpty || totalVoters <= 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No age data available\n(or no voters match current filters)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    // Filter out zero or negative counts (safety)
    final validEntries = ageGroups.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // descending by count

    if (validEntries.isEmpty) {
      return const Center(child: Text('No categorized voters'));
    }

    final total = validEntries.fold<int>(0, (sum, e) => sum + e.value);
    // Use total from valid entries (should match totalVoters if all categorized)

    final colors = [
      Colors.indigo,
      Colors.deepPurple,
      Colors.pink,
      Colors.redAccent,
    ];

    final sections = validEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value.key;
      final count = entry.value.value;

      final percentage = total > 0 ? (count / total * 100) : 0.0;

      return PieChartSectionData(
        value: count.toDouble(), // NEVER negative
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[index % colors.length],
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.58,
        badgeWidget: Text(
          _shorten(cat),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 55,
                  sectionsSpace: 2,
                  // Optional: add touchCallback for highlight
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalVoters.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Total Voters',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend (same as before, but using validEntries)
        ...validEntries.map((e) {
          final index = validEntries.indexOf(e);
          final percentage = total > 0
              ? (e.value / total * 100).toStringAsFixed(0)
              : '0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${e.key}: ${e.value} voters ($percentage%)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMainCategoriesDonut(
    Map<String, int> mainCategories,
    int totalVoters,
  ) {
    if (mainCategories.isEmpty || totalVoters <= 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No ethnic category data available\n(or no voters match current filters)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    // Filter out zero or negative counts (safety)
    final validEntries =
        mainCategories.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // descending by count

    if (validEntries.isEmpty) {
      return const Center(child: Text('No categorized voters'));
    }

    final total = validEntries.fold<int>(0, (sum, e) => sum + e.value);
    // Use total from valid entries (should match totalVoters if all categorized)

    final colors = [
      Colors.indigo,
      Colors.deepPurple,
      Colors.pink,
      Colors.redAccent,
      Colors.orange,
      Colors.amber,
      Colors.lime,
      Colors.teal,
      Colors.cyan,
      Colors.blueAccent,
    ];

    final sections = validEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value.key;
      final count = entry.value.value;

      final percentage = total > 0 ? (count / total * 100) : 0.0;

      return PieChartSectionData(
        value: count.toDouble(), // NEVER negative
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[index % colors.length],
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.58,
        badgeWidget: Text(
          _shorten(cat),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 55,
                  sectionsSpace: 2,
                  // Optional: add touchCallback for highlight
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalVoters.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Total Voters',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend (same as before, but using validEntries)
        ...validEntries.map((e) {
          final index = validEntries.indexOf(e);
          final percentage = total > 0
              ? (e.value / total * 100).toStringAsFixed(0)
              : '0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${e.key}: ${e.value} voters ($percentage%)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Helper to shorten long category names
  String _shorten(String name) {
    if (name.length > 14) return '${name.substring(0, 11)}...';
    return name;
  }

  Future<void> _exportAsExcel() async {
    try {
      final analyticsAsync = ref.read(analyticsDataProvider);
      final totalCountAsync = ref.read(totalVoterCountProvider);

      final analyticsData = await analyticsAsync.maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('Analytics data not available'),
      );

      final totalVoters = totalCountAsync.maybeWhen(
        data: (count) => count,
        orElse: () => 0,
      );

      final excel = Excel.createExcel();
      final summarySheet = excel['Summary'];
      final ageGroupsSheet = excel['Age Groups'];
      final categoriesSheet = excel['Main Categories'];

      // Extract data
      final maleCount = analyticsData['male_count'] ?? 0;
      final femaleCount = analyticsData['female_count'] ?? 0;
      final avgAge = analyticsData['avg_age'] ?? 0.0;
      final ageGroups =
          (analyticsData['age_groups'] as Map<String, dynamic>?)
              ?.map<String, int>((k, v) => MapEntry(k, v as int)) ??
          <String, int>{};
      final mainCategories =
          (analyticsData['main_categories'] as Map<String, dynamic>?)
              ?.map<String, int>((k, v) => MapEntry(k, v as int)) ??
          <String, int>{};

      // Summary Sheet
      summarySheet.appendRow([TextCellValue('Analytics Summary')]);
      summarySheet.appendRow([]);
      summarySheet.appendRow([
        TextCellValue('Total Voters'),
        IntCellValue(totalVoters),
      ]);
      summarySheet.appendRow([
        TextCellValue('Average Age'),
        DoubleCellValue(avgAge),
      ]);
      summarySheet.appendRow([
        TextCellValue('Male Count'),
        IntCellValue(maleCount),
      ]);
      summarySheet.appendRow([
        TextCellValue('Female Count'),
        IntCellValue(femaleCount),
      ]);
      summarySheet.appendRow([]);

      // Gender Distribution
      summarySheet.appendRow([TextCellValue('Gender Distribution')]);
      summarySheet.appendRow([
        TextCellValue('Gender'),
        TextCellValue('Count'),
        TextCellValue('Percentage'),
      ]);
      final totalGender = maleCount + femaleCount;
      if (totalGender > 0) {
        summarySheet.appendRow([
          TextCellValue('Male'),
          IntCellValue(maleCount),
          TextCellValue('${(maleCount / totalGender * 100).round()}%'),
        ]);
        summarySheet.appendRow([
          TextCellValue('Female'),
          IntCellValue(femaleCount),
          TextCellValue('${(femaleCount / totalGender * 100).round()}%'),
        ]);
      }

      // Age Groups Sheet
      ageGroupsSheet.appendRow([TextCellValue('Age Group Distribution')]);
      ageGroupsSheet.appendRow([]);
      ageGroupsSheet.appendRow([
        TextCellValue('Age Range'),
        TextCellValue('Count'),
        TextCellValue('Percentage'),
      ]);

      final ageTotal = ageGroups.values.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      const ageRanges = ['18-30', '31-45', '46-60', '60+'];
      for (final range in ageRanges) {
        final count = ageGroups[range] ?? 0;
        final percent = ageTotal > 0 ? (count / ageTotal * 100).round() : 0;
        ageGroupsSheet.appendRow([
          TextCellValue(range),
          IntCellValue(count),
          TextCellValue('$percent%'),
        ]);
      }

      // Main Categories Sheet
      categoriesSheet.appendRow([TextCellValue('Main Ethnic Categories')]);
      categoriesSheet.appendRow([]);
      categoriesSheet.appendRow([
        TextCellValue('Category'),
        TextCellValue('Count'),
        TextCellValue('Percentage'),
      ]);

      final sortedCategories = mainCategories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final categoryTotal = mainCategories.values.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      for (final entry in sortedCategories) {
        final percent = categoryTotal > 0
            ? (entry.value / categoryTotal * 100).round()
            : 0;
        categoriesSheet.appendRow([
          TextCellValue(entry.key),
          IntCellValue(entry.value),
          TextCellValue('$percent%'),
        ]);
      }

      // Save file
      final directory = await getExternalStorageDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'analytics_export_$timestamp.xlsx';
      final file = File('${directory!.path}/$fileName');

      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analytics exported to: ${file.path}')),
        );
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export analytics: $e')),
        );
      }
    }
  }
}
