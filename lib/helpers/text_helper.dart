String normalizeNepali(String? text) {
  if (text == null || text.trim().isEmpty) {
    return '';
  }
  return text.trim().toLowerCase();
}

String normalizeForSearch(String? text) {
  if (text == null || text.isEmpty) return '';

  String normalized = text.trim();

  // Remove ZWNJ and ZWJ (Zero Width Non-Joiner/Joiner)
  normalized = normalized.replaceAll('\u200C', '').replaceAll('\u200D', '');

  // Remove all matras/halant (including rare ones: ृ ॄ ॢ ॣ)
  // Common matras: ा ि ी ु ू े ै ो ौ ं ः ँ ृ ॄ ॢ ॣ
  normalized = normalized.replaceAll(RegExp(r'[ािीुूेैोौंःँृॄॢॣ]'), '');

  // Map conjuncts to base forms (expanded list)
  final conjunctMappings = {
    'क्ष': 'कष',
    'त्र': 'तर',
    'द्र': 'दर',
    'श्र': 'सर',
    'ज्ञ': 'गय',
    'ठ्ठ': 'ठ',
    'ष्ठ': 'स्ठ',
    'ण्ड': 'नड',
    'म्ब': 'मब',
    'च्च': 'च',
    'ज्ज': 'ज',
    'ल्ल': 'ल',
    'न्न': 'न',
    'ब्ब': 'ब',
    'द्द': 'द',
    'ग्ग': 'ग',
  };

  conjunctMappings.forEach((key, value) {
    normalized = normalized.replaceAll(key, value);
  });

  // Split common double conjuncts (e.g. चन्द्र → च न्द्र → च नदर)
  final doubleConjuncts = [
    'न्द्र',
    'म्भ',
    'क्ष्म',
    'त्क',
    'द्व',
    'स्व',
    'प्र',
    'ब्र',
    'क्र',
    'ग्र',
    'घ्र',
    'छ्र',
    'ज्र',
    'ठ्र',
    'ड्र',
    'ढ्र',
    'ण्र',
    'त्र',
    'थ्र',
    'द्र',
    'ध्र',
    'न्र',
    'प्र',
    'फ्र',
    'ब्र',
    'भ्र',
    'म्र',
    'य्र',
    'र्र',
    'ल्र',
    'व्र',
    'श्र',
    'ष्र',
    'स्र',
    'ह्र',
  ];

  for (final conjunct in doubleConjuncts) {
    if (conjunct.length >= 3) {
      final first = conjunct[0];
      final rest = conjunct.substring(1);
      normalized = normalized.replaceAll(conjunct, '$first $rest');
    }
  }

  // Normalize anusvara/visarga (remove or replace with न्/ह् if needed)
  normalized = normalized.replaceAll('ं', '').replaceAll('ः', '');

  // Remove repeated letters (e.g., रााम → राम)
  normalized = normalized.replaceAll(RegExp(r'(.)\1+'), r'$1');

  // Remove extra spaces between Devanagari characters (handle cases like "र ञ्जु" → "रञ्जु")
  // This regex finds single spaces between Devanagari characters and removes them
  normalized = normalized.replaceAllMapped(
    RegExp(r'([\u0900-\u097F])\s+([\u0900-\u097F])'),
    (match) => '${match.group(1)}${match.group(2)}',
  );

  // Remove punctuation and extra spaces
  normalized = normalized
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return normalized.toLowerCase();
}
