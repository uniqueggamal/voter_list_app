// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Fake Voter model (replace with your real model from models/voter.dart)
class Voter {
  final String name;
  final String voterId;
  final String gender; // 'M' or 'F'

  Voter({required this.name, required this.voterId, required this.gender});
}

// ── Providers ────────────────────────────────────────────────────────────────
// In real app → load from database_helper.dart
final votersProvider = StateProvider<List<Voter>>(
  (ref) => [
    // Demo data - replace with real loading
    Voter(name: "Ram Bahadur Thapa", voterId: "1234567890", gender: "M"),
    Voter(name: "Sita Kumari", voterId: "0987654321", gender: "F"),
    Voter(name: "Hari Prasad", voterId: "1122334455", gender: "M"),
    Voter(name: "Gita Rai", voterId: "6677889900", gender: "F"),
    // ... add more or load from DB
  ],
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredVotersProvider = Provider<List<Voter>>((ref) {
  final voters = ref.watch(votersProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return voters;

  return voters.where((voter) {
    final nameLower = voter.name.toLowerCase();
    final idLower = voter.voterId.toLowerCase();
    return nameLower.startsWith(query) || idLower.startsWith(query);
  }).toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showAnalytics = false;

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

  @override
  Widget build(BuildContext context) {
    final filteredVoters = ref.watch(filteredVotersProvider);
    final searchQuery = ref.watch(searchQueryProvider);

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
          // Search + Analytics toggle row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search name or voter ID (starts with)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  icon: Icon(
                    _showAnalytics ? Icons.analytics : Icons.analytics_outlined,
                  ),
                  tooltip: 'Toggle Analytics',
                  onPressed: _toggleAnalytics,
                ),
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
    final total = 174832; // placeholder
    final male = 89214;
    final female = 85618;

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

// ── Filter Panel (Bottom Sheet) ──────────────────────────────────────────────
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

          // Example filter options - expand as needed
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
