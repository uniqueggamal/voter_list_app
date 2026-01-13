import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:voter_list_app/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Analytics data test', () async {
    final dbHelper = DatabaseHelper();

    try {
      final analyticsData = await dbHelper.getAnalyticsData(groupBy: 'ward');
      print('Analytics data: $analyticsData');

      if (analyticsData.isNotEmpty) {
        final summary = analyticsData['summary'] as Map<String, dynamic>? ?? {};
        print('Summary: $summary');
        print(
          'total_voters: ${summary['total_voters']} (${summary['total_voters']?.runtimeType})',
        );
        print(
          'avg_age: ${summary['avg_age']} (${summary['avg_age']?.runtimeType})',
        );
        final gender = summary['gender'] as Map<String, dynamic>? ?? {};
        final male = gender['male'] as Map<String, dynamic>? ?? {};
        final female = gender['female'] as Map<String, dynamic>? ?? {};
        print('male_count: ${male['count']} (${male['count']?.runtimeType})');
        print(
          'female_count: ${female['count']} (${female['count']?.runtimeType})',
        );
        print('groups: ${analyticsData['groups']}');
      } else {
        print('No analytics data returned');
      }
    } catch (e, st) {
      print('Error: $e');
      print('Stack trace: $st');
    }
  });
}
