enum SearchField { voterId, name }

enum SearchMatchMode { startsWith, contains }

class SearchParams {
  final SearchField field;
  final SearchMatchMode matchMode;
  final String query;

  SearchParams({
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

  // You will use this later in queries
  String get sqlCondition {
    final col = field == SearchField.voterId
        ? 'voter_id'
        : 'name_np'; // adjust column names
    final pattern = matchMode == SearchMatchMode.startsWith
        ? '$query%'
        : '%$query%';
    return "$col LIKE '$pattern'";
  }
}
