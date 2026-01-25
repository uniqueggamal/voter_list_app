import 'package:flutter/material.dart';
import '../../models/search_models.dart';

class SearchModeSelector extends StatelessWidget {
  final SearchField selectedField;
  final ValueChanged<SearchField> onChanged;

  const SearchModeSelector({
    super.key,
    required this.selectedField,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SearchField>(
      segments: const [
        ButtonSegment(value: SearchField.name, label: Text('नामबाट')),
        ButtonSegment(value: SearchField.voterId, label: Text('ID बाट')),
        ButtonSegment(value: SearchField.tag, label: Text('ट्यागबाट')),
      ],
      selected: {selectedField},
      onSelectionChanged: (newSelection) {
        onChanged(newSelection.first);
      },
    );
  }
}
