import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voter_provider.dart';
import '../../providers/filter_provider.dart';

enum SearchMode {
  defaultMode(label: 'Name / Voter ID'),
  startsWith(label: 'Starts with');

  final String label;
  const SearchMode({required this.label});
}

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  SearchMode _selectedMode = SearchMode.defaultMode; // default

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(filterProvider).searchQuery ?? '';
    _searchController = TextEditingController(text: currentQuery);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = value.trim();
      if (query.isEmpty) {
        ref.read(filterProvider.notifier).setSearchQuery(null);
        return;
      }

      // Apply mode-specific logic
      final effectiveQuery = _selectedMode == SearchMode.startsWith
          ? '$query%' // Starts with: query%
          : '%$query%'; // Default: contains

      ref.read(filterProvider.notifier).setSearchQuery(effectiveQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sync controller when filter cleared from elsewhere
    ref.listen(filterProvider, (previous, next) {
      if (previous?.searchQuery != next.searchQuery) {
        _searchController.text = next.searchQuery?.replaceAll('%', '') ?? '';
      }
    });

    final searchQuery = ref.watch(filterProvider.select((s) => s.searchQuery));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.grey[50],
      child: Row(
        children: [
          // Dropdown for search mode
          DropdownButton<SearchMode>(
            value: _selectedMode,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            underline: const SizedBox(),
            items: SearchMode.values.map((mode) {
              return DropdownMenuItem<SearchMode>(
                value: mode,
                child: Text(mode.label, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMode = value);
                // Re-trigger search with new mode if there's text
                if (_searchController.text.trim().isNotEmpty) {
                  _onSearchChanged(_searchController.text);
                }
              }
            },
          ),

          const SizedBox(width: 12),

          // Main search field
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _selectedMode == SearchMode.startsWith
                    ? 'नाम सुरु हुने अक्षर... (उदा: क)'
                    : 'नाम, मतदाता नं. वा खोज्नुहोस्...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: searchQuery != null && searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(filterProvider.notifier)
                              .setSearchQuery(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  final effectiveQuery = _selectedMode == SearchMode.startsWith
                      ? '$query%'
                      : '%$query%';
                  ref
                      .read(filterProvider.notifier)
                      .setSearchQuery(effectiveQuery);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
