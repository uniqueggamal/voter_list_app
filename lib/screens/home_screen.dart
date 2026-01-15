import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voter_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/voter_search_provider.dart';
import '../models/search_params.dart';
import '../widgets/filter_panel_widget.dart';
import '../screens/voter_detail_screen.dart';
import '../screens/analytics_screen.dart';
import '../widgets/export_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  static const List<String> _searchFields = ['Name', 'Voter ID', 'More'];
  static const List<String> _searchModes = ['Starts with', 'Contains'];

  @override
  void initState() {
    super.initState();

    // Initial load
    Future.microtask(() {
      ref.read(voterProvider.notifier).loadVoters();
    });

    // Live search
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      ref
          .read(searchParamsProvider.notifier)
          .update((state) => state.copyWith(query: query));
      final currentFilter = ref.read(filterProvider);
      final updatedFilter = currentFilter.copyWith(searchQuery: query);
      ref.read(voterProvider.notifier).applyFiltersAndReload(updatedFilter);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDynamicHintText(SearchField field, SearchMatchMode mode) {
    final fieldText = field == SearchField.name ? 'नाम' : 'मतदाता नं.';
    final modeText = mode == SearchMatchMode.startsWith ? 'सुरुदेखि' : 'भित्रै';
    return '$fieldText खोज्नुहोस् ($modeText)...';
  }

  @override
  Widget build(BuildContext context) {
    final voterState = ref.watch(voterProvider);
    final filterState = ref.watch(filterProvider);
    final searchParams = ref.watch(searchParamsProvider);

    final isLoading = voterState.isLoading;
    final voters = voterState.voters;
    final error = voterState.loadingError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voter List - Koshi Province'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.80,
                  minChildSize: 0.4,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (_, scrollController) =>
                      FilterPanelWidget(scrollController: scrollController),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Unified Search Bar with embedded dropdowns
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                // Left dropdown: Search Field
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: searchParams.field == SearchField.name
                          ? 'Name'
                          : searchParams.field == SearchField.voterId
                          ? 'Voter ID'
                          : 'More',
                      items: _searchFields.map((field) {
                        return DropdownMenuItem<String>(
                          value: field,
                          child: Text(field),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          SearchField newField;
                          if (value == 'Name')
                            newField = SearchField.name;
                          else if (value == 'Voter ID')
                            newField = SearchField.voterId;
                          else
                            newField = SearchField.more;
                          ref
                              .read(searchParamsProvider.notifier)
                              .update(
                                (state) => state.copyWith(field: newField),
                              );
                          ref
                              .read(voterProvider.notifier)
                              .loadVoters(
                                field: newField,
                                matchMode: searchParams.matchMode,
                              );
                        }
                      },
                    ),
                  ),
                ),
                // Right dropdown: Search Mode
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:
                          searchParams.matchMode == SearchMatchMode.startsWith
                          ? 'Starts with'
                          : 'Contains',
                      items: _searchModes.map((mode) {
                        return DropdownMenuItem<String>(
                          value: mode,
                          child: Text(mode),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          SearchMatchMode newMode = value == 'Starts with'
                              ? SearchMatchMode.startsWith
                              : SearchMatchMode.contains;
                          ref
                              .read(searchParamsProvider.notifier)
                              .update(
                                (state) => state.copyWith(matchMode: newMode),
                              );
                          ref
                              .read(voterProvider.notifier)
                              .loadVoters(
                                field: searchParams.field,
                                matchMode: newMode,
                              );
                        }
                      },
                    ),
                  ),
                ),
                hintText: _getDynamicHintText(
                  searchParams.field,
                  searchParams.matchMode,
                ),
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),

          // Per page + results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'प्रति पेज:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: voterState.pageSize,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                        DropdownMenuItem(value: 100, child: Text('100')),
                        DropdownMenuItem(value: 200, child: Text('200')),
                        DropdownMenuItem(value: 500, child: Text('500')),
                        DropdownMenuItem(value: 1000, child: Text('1000')),
                        DropdownMenuItem(value: -1, child: Text('सबै')),
                      ],
                      onChanged: (newSize) {
                        if (newSize != null) {
                          ref.read(voterProvider.notifier).setPageSize(newSize);
                        }
                      },
                    ),
                  ],
                ),
                Text(
                  isLoading
                      ? 'लोड हुँदैछ...'
                      : 'फेला पर्‍यो: ${voters.length} / ${voterState.cachedTotalCount ?? "?"}',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Active filters summary
          if (filterState.hasAnyFilter)
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        filterState.summary,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(filterProvider.notifier).clearFilters();
                      ref.read(voterProvider.notifier).clearFilters();
                      _searchController.clear();
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Voter List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  )
                : voters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty &&
                                  filterState.isDefault
                              ? 'खोज्न सुरु गर्नुहोस् वा फिल्टर प्रयोग गर्नुहोस्'
                              : 'कुनै मतदाता फेला परेन',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: voters.length,
                    itemBuilder: (context, i) {
                      final v = voters[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: v.gender == 'M'
                                ? Colors.blue
                                : Colors.pink,
                            radius: 24,
                            child: Text(
                              v.gender ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            v.nameNepali ?? 'नाम उपलब्ध छैन',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${v.voterId} • उमेर: ${v.age ?? "?"}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VoterDetailScreen(voter: v),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Pagination
          if (voters.isNotEmpty && voterState.totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: voterState.canGoPrevious
                        ? ref.read(voterProvider.notifier).previousPage
                        : null,
                  ),
                  Text(
                    '${voterState.currentPage} / ${voterState.totalPages}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: voterState.canGoNext
                        ? ref.read(voterProvider.notifier).nextPage
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.analytics),
                label: const Text('Analytics'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ExportDialog(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
