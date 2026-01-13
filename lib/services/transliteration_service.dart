import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TransliterationService {
  static final TransliterationService _instance =
      TransliterationService._internal();
  static Map<String, String>? _nepaliToRomanMap;
  static Map<String, String>? _romanToNepaliMap;

  factory TransliterationService() => _instance;

  TransliterationService._internal();

  Future<void> _loadMaps() async {
    if (_nepaliToRomanMap != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/entonep.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _nepaliToRomanMap = jsonMap.map(
        (key, value) => MapEntry(key, value as String),
      );

      // Create reverse map for Roman to Nepali
      _romanToNepaliMap = {};
      for (final entry in _nepaliToRomanMap!.entries) {
        _romanToNepaliMap![entry.value] = entry.key;
      }

      debugPrint('TransliterationService: Maps loaded successfully');
    } catch (e) {
      debugPrint(
        'TransliterationService: Error loading transliteration maps: $e',
      );
      // Fallback to empty maps
      _nepaliToRomanMap = {};
      _romanToNepaliMap = {};
    }
  }

  /// Converts English phonetic text to possible Nepali Devanagari
  /// Uses the reverse map (Roman to Nepali) from the JSON
  Future<String> transliterateToNepali(String englishText) async {
    if (englishText.trim().isEmpty) return englishText;

    await _loadMaps();

    try {
      String result = englishText;
      // Sort by length descending to handle longer matches first
      final sortedKeys = _romanToNepaliMap!.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      for (final key in sortedKeys) {
        result = result.replaceAll(key, _romanToNepaliMap![key]!);
      }

      return result;
    } catch (e) {
      debugPrint('TransliterationService: Error transliterating to Nepali: $e');
      return englishText; // Fallback to original
    }
  }

  /// Converts Nepali Devanagari to Roman script
  /// Uses the direct map (Nepali to Roman) from the JSON
  Future<String> transliterateToRoman(String nepaliText) async {
    if (nepaliText.trim().isEmpty) return nepaliText;

    await _loadMaps();

    try {
      String result = nepaliText;
      // Sort by length descending to handle longer matches first
      final sortedKeys = _nepaliToRomanMap!.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      for (final key in sortedKeys) {
        result = result.replaceAll(key, _nepaliToRomanMap![key]!);
      }

      return result;
    } catch (e) {
      debugPrint('TransliterationService: Error transliterating to Roman: $e');
      return nepaliText; // Fallback to original
    }
  }
}
