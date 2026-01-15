// lib/widgets/filter_panel_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/filter_provider.dart';
import '../providers/location_repo_provider.dart';
import '../providers/voter_search_provider.dart';

class FilterPanelWidget extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const FilterPanelWidget({super.key, this.scrollController});

  @override
  ConsumerState<FilterPanelWidget> createState() => _FilterPanelWidgetState();
}

class _FilterPanelWidgetState extends ConsumerState<FilterPanelWidget> {
  bool _isExpanded = true;

  static const List<String> nepaliVowels = [
    'अ',
    'आ',
    'इ',
    'ई',
    'उ',
    'ऊ',
    'ऋ',
    'ए',
    'ऐ',
    'ओ',
    'औ',
    'अं',
    'अः',
  ];

  static const List<String> nepaliConsonants = [
    'क',
    'ख',
    'ग',
    'घ',
    'ङ',
    'च',
    'छ',
    'ज',
    'झ',
    'ञ',
    'ट',
    'ठ',
    'ड',
    'ढ',
    'ण',
    'त',
    'थ',
    'द',
    'ध',
    'न',
    'प',
    'फ',
    'ब',
    'भ',
    'म',
    'य',
    'र',
    'ल',
    'व',
    'श',
    'ष',
    'स',
    'ह',
    'क्ष',
    'त्र',
    'ज्ञ',
  ];

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final repoAsync = ref.watch(
      locationRepoProvider,
    ); // your location data source

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const Divider(height: 32),

              // Location cascade
              repoAsync.when(
                data: (repo) {
                  final provinces = repo
                      .getProvinces(); // assume returns List<String> or List<Map>
                  final districts = repo.getDistricts(
                    province: filter.province,
                  );
                  final muns = repo.getMunicipalities(
                    province: filter.province,
                    district: filter.district,
                  );
                  final wards = repo.getWards(
                    province: filter.province,
                    district: filter.district,
                    municipality: filter.municipality,
                  );
                  final booths = repo.getBooths(
                    province: filter.province,
                    district: filter.district,
                    municipality: filter.municipality,
                    wardNo: filter.wardNo,
                  );

                  final wardNos =
                      wards
                          .map((w) => w['ward_no'] as int?)
                          .whereType<int>()
                          .toList()
                        ..sort();

                  return Column(
                    children: [
                      _buildDropdown<String>(
                        label: 'Province (प्रदेश)',
                        icon: Icons.public,
                        value: filter.province,
                        items: provinces,
                        onChanged: ref
                            .read(filterProvider.notifier)
                            .setProvince,
                      ),
                      _buildDropdown<String>(
                        label: 'District (जिल्ला)',
                        icon: Icons.location_city,
                        value: filter.district,
                        items: districts,
                        onChanged: ref
                            .read(filterProvider.notifier)
                            .setDistrict,
                      ),
                      _buildDropdown<String>(
                        label: 'Municipality (नगरपालिका/गाउँपालिका)',
                        icon: Icons.location_on,
                        value: filter.municipality,
                        items: muns,
                        onChanged: ref
                            .read(filterProvider.notifier)
                            .setMunicipality,
                      ),
                      _buildDropdown<int>(
                        label: 'Ward No (वडा नं.)',
                        icon: Icons.format_list_numbered,
                        value: filter.wardNo,
                        items: wardNos,
                        itemLabel: (v) => 'Ward $v',
                        onChanged: ref.read(filterProvider.notifier).setWardNo,
                      ),
                      _buildDropdown<String>(
                        label: 'Booth (मतदान केन्द्र)',
                        icon: Icons.how_to_vote,
                        value: filter.boothCode,
                        items: booths
                            .map((b) => b['booth_code'] as String)
                            .toList(),
                        onChanged: ref
                            .read(filterProvider.notifier)
                            .setBoothCode,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Location error: $e'),
              ),

              const Divider(height: 32),

              // Gender
              _buildDropdown<String>(
                label: 'Gender (लिङ्ग)',
                icon: Icons.people,
                value: filter.gender,
                items: const ['Male', 'Female', 'Other', 'All'],
                onChanged: ref.read(filterProvider.notifier).setGender,
              ),

              const SizedBox(height: 24),

              // Age range
              const Text(
                'Age Range (उमेर समूह)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(
                  filter.minAge?.toDouble() ?? 18,
                  filter.maxAge?.toDouble() ?? 100,
                ),
                min: 18,
                max: 100,
                divisions: 82,
                labels: RangeLabels(
                  '${filter.minAge ?? 18}',
                  '${filter.maxAge ?? 100}',
                ),
                onChanged: (RangeValues values) {
                  ref
                      .read(filterProvider.notifier)
                      .setAgeRange(values.start.toInt(), values.end.toInt());
                },
              ),

              const SizedBox(height: 24),

              // Starting letter chips
              const Text(
                'Name starts with (नामको सुरुवात)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...nepaliVowels.map(
                    (l) => FilterChip(
                      label: Text(l),
                      selected: filter.startingLetter == l,
                      onSelected: (_) => ref
                          .read(filterProvider.notifier)
                          .setStartingLetter(l),
                    ),
                  ),
                  ...nepaliConsonants.map(
                    (l) => FilterChip(
                      label: Text(l),
                      selected: filter.startingLetter == l,
                      onSelected: (_) => ref
                          .read(filterProvider.notifier)
                          .setStartingLetter(l),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Main category grouping (assuming you have group_category table)
              _buildDropdown<String>(
                label: 'Main Group / Category (मुख्य समूह)',
                icon: Icons.category,
                value: filter.mainCategory,
                items: const [
                  'All',
                  'Brahmin',
                  'Chhetri',
                  'Janajati',
                  'Dalit',
                  'Madhesi',
                  'Other',
                ], // ← replace with real DB query later
                onChanged: ref.read(filterProvider.notifier).setMainCategory,
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(filterProvider.notifier).clearFilters(),
                    child: const Text('Clear All'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Apply & Refresh'),
                    onPressed: () {
                      // Force search refresh
                      ref.invalidate(voterSearchProvider);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    String Function(T)? itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T?>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All / सबै')),
          ...items.map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(itemLabel?.call(e) ?? e.toString()),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
