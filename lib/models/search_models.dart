// lib/models/search_models.dart

enum SearchField { name, voterId }

enum SearchMatchMode { startsWith, contains }

class SearchParams {
  final SearchField field;
  final SearchMatchMode matchMode;
  final String query;

  const SearchParams({
    this.field = SearchField.name,
    this.matchMode = SearchMatchMode.startsWith,
    this.query = '',
  });

  SearchParams copyWith({
    SearchField? field,
    SearchMatchMode? matchMode,
    String? query,
  }) {
    return SearchParams(
      field: field ?? this.field,
      matchMode: matchMode ?? this.matchMode,
      query: query ?? this.query,
    );
  }
}
