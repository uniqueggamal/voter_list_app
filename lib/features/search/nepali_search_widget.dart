import 'package:flutter/material.dart';
import 'nepali_search_service.dart';

enum SearchMode {
  romanToNepali('Roman → Nepali'),
  directUnicode('Direct Unicode'),
  fuzzyRomanized('Fuzzy Romanized');

  const SearchMode(this.label);
  final String label;
}

class NepaliSearchWidget extends StatefulWidget {
  const NepaliSearchWidget({super.key});

  @override
  State<NepaliSearchWidget> createState() => _NepaliSearchWidgetState();
}

class _NepaliSearchWidgetState extends State<NepaliSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  SearchMode _mode = SearchMode.romanToNepali;
  List<String> _results = [];

  // Sample data - replace with your actual data
  final _sampleData = [
    'काठमाडौं',
    'पोखरा',
    'नमस्ते नेपाल',
    'सयौं थुँगा फूलका हामी',
    'एउटै माला नेपाली',
  ];

  late final NepaliSearchService _searchService;

  @override
  void initState() {
    super.initState();
    _searchService = NepaliSearchService(_sampleData);
  }

  void _performSearch(String query) {
    setState(() {
      switch (_mode) {
        case SearchMode.romanToNepali:
          _results = _searchService.searchRomanToNepali(query);
          break;
        case SearchMode.directUnicode:
          _results = _searchService.searchDirectUnicode(query);
          break;
        case SearchMode.fuzzyRomanized:
          _results = _searchService.searchFuzzyRomanized(query);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode selector
        Row(
          children: SearchMode.values.map((mode) {
            return Expanded(
              child: RadioListTile<SearchMode>(
                title: Text(mode.label, style: const TextStyle(fontSize: 12)),
                value: mode,
                groupValue: _mode,
                onChanged: (value) {
                  setState(() => _mode = value!);
                  _performSearch(_controller.text);
                },
              ),
            );
          }).toList(),
        ),

        // Search field
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: _performSearch,
        ),

        const SizedBox(height: 16),

        // Results
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(_results[index]));
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
