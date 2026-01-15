import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_models.dart'; // SearchParams, SearchField, SearchMatchMode
import '../providers/voter_search_provider.dart'; // voterSearchProvider, etc.
import '../providers/filter_provider.dart'; // filterProvider (your custom one)
import '../widgets/filter_panel_widget.dart'; // your FilterPanelWidget

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Simple debounce can be added later if needed
      ref.read(searchParamsProvider.notifier).state = ref
          .read(searchParamsProvider)
          .copyWith(query: _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDynamicHintText(SearchParams params) {
    final fieldText = params.field == SearchField.name ? 'नाम' : 'मतदाता नं.';
    final modeText = params.matchMode == SearchMatchMode.startsWith
        ? 'सुरुदेखि'
        : 'भित्रै';
    return '$fieldText खोज्नुहोस् ($modeText)...';
  }

  @override
  Widget build(BuildContext context) {
    final searchParams = ref.watch(searchParamsProvider);
    final searchAsync = ref.watch(voterSearchProvider(searchParams));
    final resultCount = ref.watch(searchResultCountProvider);
    final filterState = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voter List - Koshi Province'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollController) =>
                    FilterPanelWidget(scrollController: scrollController),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SearchMatchMode>(
                      value: searchParams.matchMode,
                      items: const [
                        DropdownMenuItem(
                          value: SearchMatchMode.startsWith,
                          child: Text('Starts with'),
                        ),
                        DropdownMenuItem(
                          value: SearchMatchMode.contains,
                          child: Text('Contains'),
                        ),
                      ],
                      onChanged: (v) => v != null
                          ? ref.read(searchParamsProvider.notifier).state =
                                searchParams.copyWith(matchMode: v)
                          : null,
                    ),
                  ),
                ),
                hintText: _getDynamicHintText(searchParams),
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SearchField>(
                      value: searchParams.field,
                      items: const [
                        DropdownMenuItem(
                          value: SearchField.name,
                          child: Text('Name'),
                        ),
                        DropdownMenuItem(
                          value: SearchField.voterId,
                          child: Text('ID'),
                        ),
                      ],
                      onChanged: (v) => v != null
                          ? ref.read(searchParamsProvider.notifier).state =
                                searchParams.copyWith(field: v)
                          : null,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),

          // Active filters summary (small chip bar)
          if (filterState.hasAnyFilter)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  if (filterState.district != null)
                    Chip(label: Text('District: ${filterState.district}')),
                  if (filterState.municipality != null)
                    Chip(label: Text('Mun: ${filterState.municipality}')),
                  if (filterState.wardNo != null)
                    Chip(label: Text('Ward: ${filterState.wardNo}')),
                  if (filterState.gender != null)
                    Chip(label: Text('Gender: ${filterState.gender}')),
                  if (filterState.minAge != null || filterState.maxAge != null)
                    Chip(
                      label: Text(
                        'Age: ${filterState.minAge ?? 18}–${filterState.maxAge ?? 100}',
                      ),
                    ),
                  if (filterState.startingLetter != null)
                    Chip(label: Text('Starts: ${filterState.startingLetter}')),
                ],
              ),
            ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  searchParams.query.isEmpty
                      ? 'खोज्न सुरु गर्नुहोस्...'
                      : 'फेला पर्‍यो: $resultCount जना',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: () {
                        // TODO: previous page logic (pageProvider.state--)
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 20),
                      onPressed: () {
                        // TODO: next page logic (pageProvider.state++)
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Voter list
          Expanded(
            child: searchAsync.when(
              data: (voters) {
                if (voters.isEmpty && searchParams.query.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'कुनै मतदाता फेला परेन\nफरक तरिकाले खोज्नुहोस्',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: voters.length,
                  itemBuilder: (context, i) {
                    final v = voters[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: v.gender == 'M'
                              ? Colors.blue
                              : Colors.pink,
                          child: Text(
                            v.gender,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          v.nameNepali,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'ID: ${v.voterId} • Age: ${v.age ?? "?"}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: detail screen
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Analytics'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analytics view coming soon...'),
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export feature coming soon...'),
                    ),
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
