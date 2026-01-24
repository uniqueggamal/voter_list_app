import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voter.dart';
import '../providers/voter_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/filter_panel_widget.dart';
import 'voter_detail_screen.dart';

class VotersListScreen extends ConsumerStatefulWidget {
  const VotersListScreen({super.key});

  @override
  ConsumerState<VotersListScreen> createState() => _VotersListScreenState();
}

class _VotersListScreenState extends ConsumerState<VotersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(filterProvider.notifier).setSearchQuery(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Declare these at the TOP of build()
    final filterState = ref.watch(filterProvider);
    final voterProviderInstance = ref.watch(voterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voters List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              ref.read(filterProvider.notifier).clearFilters();
              _searchController.clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name (English or Nepali)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Active Filters Display
          if (_hasActiveFilters(filterState))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(filterState),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Voters List
          Expanded(
            child: voterProviderInstance.isLoading
                ? const Center(child: CircularProgressIndicator())
                : voterProviderInstance.voters.isEmpty
                ? const Center(child: Text('No voters found'))
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(voterProvider.notifier).loadVoters(),
                    child: ListView.builder(
                      itemCount: voterProviderInstance.voters.length,
                      itemBuilder: (context, index) {
                        final voter = voterProviderInstance.voters[index];
                        return VoterCard(voter: voter);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(FilterState filter) {
    return filter.province != null ||
        filter.district != null ||
        filter.municipality != null ||
        filter.wardNo != null ||
        filter.boothCode != null ||
        filter.gender != null ||
        filter.minAge != null ||
        filter.maxAge != null ||
        filter.startingLetter != null ||
        (filter.searchQuery?.isNotEmpty ?? false);
  }

  String _getActiveFiltersText(FilterState filter) {
    final parts = <String>[];
    if (filter.province != null) parts.add('Province: ${filter.province}');
    if (filter.district != null) parts.add('District: ${filter.district}');
    if (filter.municipality != null)
      parts.add('Municipality: ${filter.municipality}');
    if (filter.wardNo != null) parts.add('Ward: ${filter.wardNo}');
    if (filter.boothCode != null) parts.add('Booth: ${filter.boothCode}');
    if (filter.gender != null) parts.add('Gender: ${filter.gender}');
    if (filter.minAge != null || filter.maxAge != null) {
      parts.add('Age: ${filter.minAge ?? 18}–${filter.maxAge ?? 100}');
    }
    if (filter.startingLetter != null)
      parts.add('Starts with: ${filter.startingLetter}');
    if (filter.searchQuery?.isNotEmpty == true) {
      parts.add('Search: "${filter.searchQuery}"');
    }
    return parts.join(' • ');
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const FilterPanelWidget(), // ← now works without parameters
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All Filters'),
                  onPressed: () {
                    ref.read(filterProvider.notifier).clearFilters();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoterCard extends StatelessWidget {
  final Voter voter;
  const VoterCard({super.key, required this.voter});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VoterDetailScreen(voter: voter)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                voter.nameNepali,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Voter No: ${voter.voterNo}'),
                  const SizedBox(width: 16),
                  if (voter.age != null) Text('Age: ${voter.age}'),
                  const SizedBox(width: 16),
                  Text(voter.gender),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${voter.municipality} - Ward ${voter.wardNo} - ${voter.boothName}',
              ),
              Text('${voter.district}, ${voter.province}'),
            ],
          ),
        ),
      ),
    );
  }
}
