String normalizeNepali(String? text) {
  if (text == null || text.trim().isEmpty) {
    return '';
  }
  return text.trim().toLowerCase();
}

String normalizeForSearch(String? text) {
  if (text == null || text.isEmpty) return '';
  return text
      .trim()
      .replaceAll('\u200C', '') // ZWNJ
      .replaceAll('\u200D', '') // ZWJ
      .toLowerCase();
}
