import 'package:flutter/material.dart';

class AnalyticsDialog extends StatelessWidget {
  final Map<String, dynamic> analyticsData;

  const AnalyticsDialog({super.key, required this.analyticsData});

  @override
  Widget build(BuildContext context) {
    final data = analyticsData;

    return AlertDialog(
      title: const Text('Voter Analytics'),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Summary Stats
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const Divider(),
                      _buildStatRow('Total Voters', _formatNumber(data['total_voters'])),
                      _buildStatRow(
                        'Average Age',
                        _formatNumber(data['avg_age'], fraction: 1),
                      ),
                      _buildStatRow('Male Voters', _formatNumber(data['male_count'])),
                      _buildStatRow('Female Voters', _formatNumber(data['female_count'])),
                      _buildStatRow('Total Booths', _formatNumber(data['booth_count'])),
                      _buildStatRow('Total Wards', _formatNumber(data['ward_count'])),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Grouped Analytics
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analytics by Group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const Divider(),

                      if (data['by_province'] != null)
                        _buildGroupSection(
                          'By Province',
                          data['by_province'] as Map<String, dynamic>,
                        ),

                      if (data['by_district'] != null)
                        _buildGroupSection(
                          'By District',
                          data['by_district'] as Map<String, dynamic>,
                        ),

                      if (data['by_municipality'] != null)
                        _buildGroupSection(
                          'By Municipality',
                          data['by_municipality'] as Map<String, dynamic>,
                        ),

                      if (data['by_ward'] != null)
                        _buildGroupSection(
                          'By Ward (Top 10)',
                          data['by_ward'] as Map<String, dynamic>,
                          limit: 10,
                        ),

                      if (data['by_booth'] != null)
                        _buildGroupSection(
                          'By Booth (Top 10)',
                          data['by_booth'] as Map<String, dynamic>,
                          limit: 10,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  // Moved formatNumber here as a private class method
  String _formatNumber(dynamic value, {int fraction = 0}) {
    if (value == null) return '0';
    if (value is num) {
      return fraction > 0
          ? value.toStringAsFixed(fraction)
          : value.toInt().toString();
    }
    return value.toString();
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
    String title,
    Map<String, dynamic> groupData, {
    int? limit,
  }) {
    final sortedEntries = groupData.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    final displayEntries = limit != null ? sortedEntries.take(limit) : sortedEntries;

    if (displayEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...displayEntries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      _formatNumber(entry.value), // ← now accessible
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}