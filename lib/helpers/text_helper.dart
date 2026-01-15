String normalizeNepali(String? text) {
  if (text == null || text.trim().isEmpty) {
    return '';
  }
  return text.trim().toLowerCase();
}
