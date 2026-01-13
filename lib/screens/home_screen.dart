// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Search Modes ─────────────────────────────────────────────────────────────
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

// ── Providers ────────────────────────────────────────────────────────────────
final votersProvider = StateProvider<List<Voter>>(
  (ref) => [
    Voter(name: "Ram Bahadur Thapa", voterId: "1234567890", gender: "M"),
    Voter(name: "Sita Kumari", voterId: "0987654321", gender: "F"),
    Voter(name: "Hari Prasad", voterId: "1122334455", gender: "M"),
    Voter(name: "Gita Rai", voterId: "6677889900", gender: "F"),
    // ... add more or load from DB
  ],
);

final searchParamsProvider = StateProvider<SearchParams>(
  (ref) => const SearchParams(),
);

final filteredVotersProvider = Provider<List<Voter>>((ref) {
  final voters = ref.watch(votersProvider);
  final params = ref.watch(searchParamsProvider);

  if (params.query.isEmpty) return voters;

  final queryLower = params.query.trim().toLowerCase();

  return voters.where((voter) {
    final value = params.field == SearchField.name
        ? voter.name.toLowerCase()
        : voter.voterId.toLowerCase();

    return params.matchMode == SearchMatchMode.startsWith
        ? value.startsWith(queryLower)
        : value.contains(queryLower);
  }).toList();
});

// ── Fake Voter model (replace with real model later)
class Voter {
  final String name;
  final String voterId;
  final String gender; // 'M' or 'F'

  Voter({required this.name, required this.voterId, required this.gender});
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showAnalytics = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text;
      ref.read(searchParamsProvider.notifier).state = ref
          .read(searchParamsProvider)
          .copyWith(query: query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleAnalytics() {
    setState(() => _showAnalytics = !_showAnalytics);
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return FilterPanel(scrollController: scrollController);
        },
      ),
    );
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
    final filteredVoters = ref.watch(filteredVotersProvider);
    final searchParams = ref.watch(searchParamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voter List - Koshi Province'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: _showFilterPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search mode selector (Name / Voter ID)
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    // ── LEFT: Match mode (Starts with / Contains) ────────────────────────────
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SearchMatchMode>(
                          value: searchParams.matchMode,
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.black87,
                          ),
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
                          onChanged: (SearchMatchMode? newMode) {
                            if (newMode != null) {
                              ref.read(searchParamsProvider.notifier).state =
                                  searchParams.copyWith(matchMode: newMode);
                            }
                          },
                        ),
                      ),
                    ),

                    // ── MIDDLE: Search input ─────────────────────────────────────────────────
                    hintText: _getDynamicHintText(searchParams),
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),

                    // ── RIGHT: Field selector (Name / ID / More...) ──────────────────────────
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8, left: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SearchField>(
                          value: searchParams.field,
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          alignment: Alignment.centerRight,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.black87,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: SearchField.name,
                              child: Text('Name'),
                            ),
                            DropdownMenuItem(
                              value: SearchField.voterId,
                              child: Text('ID'),
                            ),
                            DropdownMenuItem(
                              value: null,
                              enabled:
                                  false, // placeholder - change when you add real mode
                              child: Text(
                                'More...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                          onChanged: (SearchField? newValue) {
                            if (newValue == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'थप विकल्पहरू चाँडै आउँदैछन्...',
                                  ),
                                ),
                              );
                              return;
                            }
                            ref.read(searchParamsProvider.notifier).state =
                                searchParams.copyWith(field: newValue);
                          },
                        ),
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 8),

                // Starts with / Contains toggle
                // Search field selection - Dropdown
              ],
            ),
          ),

          // Analytics row (shows/hides)
          if (_showAnalytics)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildAnalyticsRow(),
            ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Found ${filteredVoters.length} voters',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Voter List
          Expanded(
            child: ListView.builder(
              itemCount: filteredVoters.length,
              itemBuilder: (context, index) {
                final voter = filteredVoters[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: voter.gender == 'M'
                        ? Colors.blue
                        : Colors.pink,
                    child: Text(
                      voter.gender,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(voter.name),
                  subtitle: Text('Voter ID: ${voter.voterId}'),
                  onTap: () {
                    // TODO: Go to detail screen
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow() {
    // In real app → use FutureProvider + database queries
    const total = 174832;
    const male = 89214;
    const female = 85618;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(title: 'Total', value: total, color: Colors.blue),
            _StatItem(title: 'Male', value: male, color: Colors.indigo),
            _StatItem(title: 'Female', value: female, color: Colors.pink),
          ],
        ),
      ),
    );
  }
}

// ── StatItem & FilterPanel remain the same ──────────────────────────────────
class _StatItem extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class FilterPanel extends StatelessWidget {
  final ScrollController scrollController;

  const FilterPanel({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          const ListTile(
            leading: Icon(Icons.location_on),
            title: Text('District / Municipality'),
            subtitle: Text('All selected'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.people),
            title: Text('Gender'),
            subtitle: Text('All'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Age Group'),
            subtitle: Text('18–100'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
