import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_provider.dart';
import '../providers/voter_provider.dart';

class FilterPanelWidget extends ConsumerStatefulWidget {
  // final VoidCallback onApplyFilters;

  const FilterPanelWidget({super.key});

  @override
  ConsumerState<FilterPanelWidget> createState() => _FilterPanelWidgetState();
}

class _FilterPanelWidgetState extends ConsumerState<FilterPanelWidget> {
  bool _isExpanded = true;

  // Nepali vowels (for starting letter filter)
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

  // Common Nepali consonants (you can expand this list as needed)
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
    final filterState = ref.watch(filterProvider);
    final repoAsync = ref.watch(locationRepoProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header with expand/collapse
          ListTile(
            leading: Icon(
              _isExpanded ? Icons.filter_list : Icons.filter_list_off,
            ),
            title: const Text(
              'Filters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),

          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: repoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading locations: $e'),
                data: (repo) {
                  final provinces = repo.getProvinces();
                  final districts = repo.getDistricts(
                    province: filterState.province,
                  );
                  final municipalities = repo.getMunicipalities(
                    province: filterState.province,
                    district: filterState.district,
                  );
                  final wards = repo.getWards(
                    province: filterState.province,
                    district: filterState.district,
                    municipality: filterState.municipality,
                  );
                  final booths = repo.getBooths(
                    province: filterState.province,
                    district: filterState.district,
                    municipality: filterState.municipality,
                    wardNo: filterState.wardNo,
                  );

                  final wardNos =
                      wards
                          .map((w) => w['ward_no'] as int?)
                          .whereType<int>()
                          .toSet()
                          .toList()
                        ..sort();

                  final boothCodes = booths
                      .map((b) => b['booth_code'] as String?)
                      .whereType<String>()
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Location Filters ──
                      _dropdown<String>(
                        label: 'Province',
                        value: filterState.province,
                        items: provinces,
                        onChanged: (v) =>
                            ref.read(filterProvider.notifier).setProvince(v),
                      ),
                      _dropdown<String>(
                        label: 'District',
                        value: filterState.district,
                        items: districts,
                        onChanged: (v) =>
                            ref.read(filterProvider.notifier).setDistrict(v),
                      ),
                      _dropdown<String>(
                        label: 'Municipality',
                        value: filterState.municipality,
                        items: municipalities,
                        onChanged: (v) => ref
                            .read(filterProvider.notifier)
                            .setMunicipality(v),
                      ),
                      _dropdown<int>(
                        label: 'Ward',
                        value: filterState.wardNo,
                        items: wardNos,
                        itemLabel: (v) => 'Ward $v',
                        onChanged: (v) =>
                            ref.read(filterProvider.notifier).setWardNo(v),
                      ),
                      _dropdown<String>(
                        label: 'Booth',
                        value: filterState.boothCode,
                        items: boothCodes,
                        onChanged: (v) =>
                            ref.read(filterProvider.notifier).setBoothCode(v),
                      ),

                      const Divider(height: 32),

                      // ── Gender Filter ──
                      _dropdown<String>(
                        label: 'Gender',
                        value: filterState.gender,
                        items: const ['Male', 'Female', 'Other'],
                        itemLabel: (v) => v,
                        onChanged: (v) =>
                            ref.read(filterProvider.notifier).setGender(v),
                      ),

                      const SizedBox(height: 16),

                      // ── Starting Letter Filter ──
                      const Text(
                        'Name starts with:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Vowel chips
                          ...nepaliVowels.map(
                            (letter) => FilterChip(
                              label: Text(letter),
                              selected: filterState.startingLetter == letter,
                              onSelected: (_) => ref
                                  .read(filterProvider.notifier)
                                  .setStartingLetter(letter),
                            ),
                          ),

                          // Consonant chips (in a separate group)
                          ...nepaliConsonants.map(
                            (letter) => FilterChip(
                              label: Text(letter),
                              selected: filterState.startingLetter == letter,
                              onSelected: (_) => ref
                                  .read(filterProvider.notifier)
                                  .setStartingLetter(letter),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Apply & Clear buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              ref.read(filterProvider.notifier).clearFilters();
                            },
                            child: const Text('Clear All'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.analytics),
                            label: const Text('Update Analytics'),
                            onPressed: () async {
                              final currentFilter = ref.read(filterProvider);
                              await ref
                                  .read(voterProvider.notifier)
                                  .applyFiltersAndReload(currentFilter);
                              // Load fresh analytics data after applying filters
                              await ref
                                  .read(voterProvider.notifier)
                                  .loadAnalyticsData();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T?>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text('All')),
          ...items.map(
            (e) => DropdownMenuItem<T?>(
              value: e,
              child: Text(itemLabel?.call(e) ?? '$e'),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
