import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voter_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/voter_search_provider.dart';
import '../models/search_models.dart';
import '../widgets/filter_panel_widget.dart';
import '../screens/voter_detail_screen.dart';
import '../screens/analytics_screen.dart';
import '../widgets/export_dialog.dart';
import '../widgets/tags_dialog.dart';
import '../helpers/database_helper.dart';
import '../helpers/tags_database_helper.dart';
import '../services/import_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final Map<int, List<Map<String, dynamic>>> _voterTagsCache = {};

  // Helper method to determine gender color and display text
  ({Color color, String displayText}) _getGenderStyle(String? gender) {
    if (gender == null || gender.trim().isEmpty) {
      return (color: Colors.grey, displayText: '?');
    }

    final normalizedGender = gender.trim().toLowerCase();

    // Check for female first (more specific patterns)
    if (normalizedGender == 'f' ||
        normalizedGender == 'female' ||
        normalizedGender.contains('female') ||
        normalizedGender.contains('महिला') ||
        normalizedGender == 'महि' ||
        normalizedGender == 'फ' ||
        normalizedGender == 'female') {
      return (color: Colors.pink, displayText: 'F');
    }

    // Check for male
    if (normalizedGender == 'm' ||
        normalizedGender == 'male' ||
        normalizedGender.contains('male') ||
        normalizedGender.contains('पुरुष') ||
        normalizedGender == 'पु' ||
        normalizedGender == 'म' ||
        normalizedGender == 'male') {
      return (color: Colors.blue, displayText: 'M');
    }

    // Default fallback
    return (
      color: Colors.grey,
      displayText: gender.substring(0, 1).toUpperCase(),
    );
  }

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
      Future(() {
        ref
            .read(searchParamsProvider.notifier)
            .update((state) => state.copyWith(query: query));
        final currentFilter = ref.read(filterProvider);
        final updatedFilter = currentFilter.copyWith(searchQuery: query);
        ref.read(voterProvider.notifier).applyFiltersAndReload(updatedFilter);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync search controller with current search state
    final currentQuery = ref.read(searchParamsProvider).query;
    if (_searchController.text != currentQuery) {
      _searchController.text = currentQuery;
    }
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

  Future<void> _onRefresh() async {
    // Force reload data from DB on refresh
    await ref.read(voterProvider.notifier).forceReload();
    // Clear tags cache
    _voterTagsCache.clear();
  }

  Future<List<Map<String, dynamic>>> _getVoterTags(int voterId) async {
    if (_voterTagsCache.containsKey(voterId)) {
      return _voterTagsCache[voterId]!;
    }

    try {
      final tags = await TagsDatabaseHelper().getTagsForVoter(voterId);
      // Convert Tag objects to Map for consistency
      final tagMaps = tags
          .map(
            (tag) => {
              'name': tag.name,
              'color': tag.color,
              'category':
                  'tag', // Default category since Tag model doesn't have it
            },
          )
          .toList();
      _voterTagsCache[voterId] = tagMaps;
      return tagMaps;
    } catch (e) {
      // Return empty list on error
      return [];
    }
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                showDialog(
                  context: context,
                  builder: (_) => const ExportDialog(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('Tags'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                showDialog(
                  context: context,
                  builder: (_) => const TagsDialog(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Import'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                ImportService().importExcelFile(context);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            // Menu button, Filter inside Search Bar Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Menu',
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) => DraggableScrollableSheet(
                                initialChildSize: 0.80,
                                minChildSize: 0.4,
                                maxChildSize: 0.95,
                                expand: false,
                                builder: (_, scrollController) =>
                                    FilterPanelWidget(
                                      scrollController: scrollController,
                                    ),
                              ),
                            );
                          },
                          child: const Icon(Icons.filter_list),
                        ),
                        suffixIcon: const Icon(Icons.search),
                        hintText: 'खोज्नुहोस्...',
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
                ],
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
                            ref
                                .read(voterProvider.notifier)
                                .setPageSize(newSize);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
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
                        // Calculate absolute serial number (not bound by page)
                        final serialNumber =
                            (voterState.currentPage - 1) * voterState.pageSize +
                            (i + 1);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: SizedBox(
                              width: 60,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final genderStyle = _getGenderStyle(
                                        v.gender,
                                      );
                                      return CircleAvatar(
                                        backgroundColor: genderStyle.color,
                                        radius: 20,
                                        child: Text(
                                          serialNumber.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _getVoterTags(v.id),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data!.isNotEmpty) {
                                        final tags = snapshot.data!;
                                        final firstTag = tags.first;
                                        final hasMore = tags.length > 1;

                                        return Container(
                                          width: 52,
                                          height: 12,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              int.parse(
                                                '0xff${firstTag['color'].replaceFirst('#', '')}',
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            hasMore
                                                ? '+more'
                                                : firstTag['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 7,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                              v.nameNepali ?? 'नाम उपलब्ध छैन',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: ${v.voterId} • उमेर: ${v.age ?? "?"}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (v.boothName.isNotEmpty)
                                    Text(
                                      'बुथ: ${v.boothName}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
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
      ),
    );
  }
}
