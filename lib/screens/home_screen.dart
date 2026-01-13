import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voter_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_panel.dart';
import '../widgets/voter_list.dart';
import '../widgets/analytics_button.dart';
import '../widgets/export_button.dart';
import '../widgets/loading_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load initial voters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voterProvider.notifier).loadVoters();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Optional: future infinite scroll can be added here
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the VoterProvider state
    final voterState = ref.watch(voterProvider);
    final voterNotifier = ref.read(voterProvider.notifier);

    // Setup filter listener
    ref.listen(filterProvider, (previous, next) {
      ref.read(voterProvider.notifier).applyFiltersAndReload(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 40),
        actions: [
          const ExportButtonWidget(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => voterNotifier.loadVoters(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => voterNotifier.loadVoters(),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Search & Filters
              const SearchBarWidget(),
              const FilterPanelWidget(),

              // Pagination & Stats Controls
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnalyticsButtonWidget(parentContext: context),
                        const Spacer(),
                        Flexible(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final totalCountAsync = ref.watch(
                                totalVoterCountProvider,
                              );
                              return totalCountAsync.maybeWhen(
                                data: (totalCount) => Text(
                                  '$totalCount voters',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                ),
                                loading: () => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                orElse: () => const Text('...'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Show: ', style: TextStyle(fontSize: 13)),
                        DropdownButton<int>(
                          value: voterState.pageSize,
                          items: const [
                            DropdownMenuItem(
                              value: 10,
                              child: Text(
                                '10',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 100,
                              child: Text(
                                '100',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 500,
                              child: Text(
                                '500',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 1000,
                              child: Text(
                                '1000',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            DropdownMenuItem(
                              value: -1,
                              child: Text(
                                'All',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              voterNotifier.setPageSize(value);
                            }
                          },
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (voterState.pageSize != -1) ...[
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: voterState.canGoPrevious
                                ? voterNotifier.previousPage
                                : null,
                            iconSize: 20,
                          ),
                          Text(
                            '${voterState.currentPage} / ${voterState.totalPages}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: voterState.canGoNext
                                ? voterNotifier.nextPage
                                : null,
                            iconSize: 20,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Voter List
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: const VoterListWidget(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
