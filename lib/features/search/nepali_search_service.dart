import 'package:nepali_utils/nepali_utils.dart';
import 'package:string_similarity/string_similarity.dart';

/// Service for offline Nepali search with multiple modes
class NepaliSearchService {
  final List<String> data;

  NepaliSearchService(this.data);

  /// Mode 1: Roman → Nepali conversion + search
  List<String> searchRomanToNepali(String query) {
    if (query.isEmpty) return [];
    try {
      final nepaliQuery = NepaliUnicode.convert(query);
      return data.where((item) => item.contains(nepaliQuery)).toList();
    } catch (e) {
      // Fallback to direct search if conversion fails
      return data.where((item) => item.contains(query)).toList();
    }
  }

  /// Mode 2: Direct Unicode search
  List<String> searchDirectUnicode(String query) {
    if (query.isEmpty) return [];
    return data.where((item) => item.contains(query)).toList();
  }

  /// Mode 3: Fuzzy search on romanized versions
  List<String> searchFuzzyRomanized(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    final results = <MapEntry<String, double>>[];

    for (final item in data) {
      try {
        final romanized = NepaliUnicode.convert(item);
        final similarity = lowerQuery.similarityTo(romanized.toLowerCase());
        if (similarity > 0.7) {
          results.add(MapEntry(item, similarity));
        }
      } catch (e) {
        // Skip if conversion fails
      }
    }

    // Sort by similarity descending
    results.sort((a, b) => b.value.compareTo(a.value));
    return results.map((e) => e.key).toList();
  }
}
