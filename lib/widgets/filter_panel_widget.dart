// lib/widgets/filter_panel_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/filter_provider.dart';
import '../providers/location_repo_provider.dart';
import '../providers/voter_provider.dart';
import '../providers/voter_search_provider.dart';
import '../models/search_models.dart';

class FilterPanelWidget extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const FilterPanelWidget({super.key, this.scrollController});

  @override
  ConsumerState<FilterPanelWidget> createState() => _FilterPanelWidgetState();
}

class _FilterPanelWidgetState extends ConsumerState<FilterPanelWidget> {
  bool _isExpanded = true;
  String _filterMode = 'Normal'; // 'Normal' or 'Advanced'

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

              // Search Field and Mode
              Consumer(
                builder: (context, ref, child) {
                  final searchParams = ref.watch(searchParamsProvider);
                  return Column(
                    children: [
                      _buildDropdown<String>(
                        label: 'Search Field (खोज क्षेत्र)',
                        icon: Icons.search,
                        value: searchParams.field == SearchField.name
                            ? 'Name'
                            : searchParams.field == SearchField.voterId
                            ? 'Voter ID'
                            : searchParams.field == SearchField.tag
                            ? 'Tag'
                            : 'More',
                        items: const ['Name', 'Voter ID', 'Tag', 'More'],
                        onChanged: (value) {
                          if (value != null) {
                            SearchField? newField;
                            if (value == 'Name')
                              newField = SearchField.name;
                            else if (value == 'Voter ID')newField = SearchField.voterId;
                            else if (value == 'Tag')
                              newField = SearchField.tag;
                            else
                              newField = SearchField.more;
                            ref
                                .read(searchParamsProvider.notifier)
                                .update(
                                  (state) => state.copyWith(field: newField),
                                );
                            ref.read(voterProvider.notifier).loadVoters();
                          }
                        },
                      ),
                      _buildDropdown<String>(
                        label: 'Search Mode (खोज मोड)',
                        icon: Icons.filter_list,
                        value:
                            filter.searchMatchMode == SearchMatchMode.startsWith
                            ? 'Starts with'
                            : 'Contains',
                        items: const ['Starts with', 'Contains'],
                        onChanged: (value) {
                          if (value != null) {
                            SearchMatchMode newMode = value == 'Starts with'
                                ? SearchMatchMode.startsWith
                                : SearchMatchMode.contains;
                            ref
                                .read(filterProvider.notifier)
                                .setSearchMatchMode(newMode);
                            ref.read(voterProvider.notifier).loadVoters();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),

              const Divider(height: 32),

              // Filter Mode Selector
              _buildDropdown<String>(
                label: 'Filter Mode (फिल्टर मोड)',
                icon: Icons.filter_alt,
                value: _filterMode,
                items: const ['Normal', 'Advanced'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _filterMode = value);
                  }
                },
              ),

              const Divider(height: 32),

              // Location Selection based on mode
              repoAsync.when(
                data: (repo) {
                  final filter = ref.watch(filterProvider);
                  return ExpansionTile(
                    title: const Text(
                      'Advanced Location Selection',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _filterMode == 'Advanced'
                            ? [
                                const Text(
                                  'Select multiple values to search across:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Multi-select Provinces
                                _buildMultiSelect<String>(
                                  label: 'Provinces (प्रदेशहरू)',
                                  icon: Icons.public,
                                  selectedValues:
                                      filter.selectedProvinces ?? [],
                                  allValues: repo.getProvinces(),
                                  onChanged: (values) => ref
                                      .read(filterProvider.notifier)
                                      .setSelectedProvinces(values),
                                ),
                                // Multi-select Districts
                                if ((filter.selectedProvinces ?? []).isNotEmpty)
                                  _buildMultiSelect<String>(
                                    label: 'Districts (जिल्लाहरू)',
                                    icon: Icons.location_city,
                                    selectedValues:
                                        filter.selectedDistricts ?? [],
                                    allValues: filter.selectedProvinces!
                                        .expand(
                                          (province) => repo.getDistricts(
                                            province: province,
                                          ),
                                        )
                                        .toSet()
                                        .toList()
                                        .cast<String>(),
                                    onChanged: (values) => ref
                                        .read(filterProvider.notifier)
                                        .setSelectedDistricts(values),
                                  ),
                                // Multi-select Municipalities
                                if ((filter.selectedDistricts ?? []).isNotEmpty)
                                  _buildMultiSelect<String>(
                                    label:
                                        'Municipalities (नगरपालिकाहरू/गाउँपालिकाहरू)',
                                    icon: Icons.location_on,
                                    selectedValues:
                                        filter.selectedMunicipalities ?? [],
                                    allValues: filter.selectedDistricts!
                                        .expand(
                                          (district) => repo.getMunicipalities(
                                            province: filter.selectedProvinces!
                                                .firstWhere(
                                                  (p) => repo
                                                      .getDistricts(province: p)
                                                      .contains(district),
                                                  orElse: () => '',
                                                ),
                                            district: district,
                                          ),
                                        )
                                        .toSet()
                                        .toList()
                                        .cast<String>(),
                                    onChanged: (values) => ref
                                        .read(filterProvider.notifier)
                                        .setSelectedMunicipalities(values),
                                  ),
                                // Multi-select Wards
                                if ((filter.selectedMunicipalities ?? [])
                                    .isNotEmpty)
                                  _buildMultiSelect<Map<String, dynamic>>(
                                    label: 'Wards (वडाहरू)',
                                    icon: Icons.format_list_numbered,
                                    selectedValues:
                                        filter.selectedWards
                                            ?.map(
                                              (ward) => {
                                                'ward_no': ward,
                                                'municipality':
                                                    filter
                                                        .selectedMunicipalities
                                                        ?.firstWhere(
                                                          (m) => repo
                                                              .getWards(
                                                                province: filter
                                                                    .selectedProvinces!
                                                                    .first,
                                                                district: filter
                                                                    .selectedDistricts!
                                                                    .first,
                                                                municipality: m,
                                                              )
                                                              .any(
                                                                (w) =>
                                                                    (w['ward_no']
                                                                        as int?) ==
                                                                    ward,
                                                              ),
                                                          orElse: () => '',
                                                        ) ??
                                                    '',
                                              },
                                            )
                                            .toList() ??
                                        [],
                                    allValues:
                                        filter.selectedMunicipalities!
                                            .expand(
                                              (municipality) => repo
                                                  .getWards(
                                                    province: filter
                                                        .selectedProvinces!
                                                        .firstWhere(
                                                          (p) => repo
                                                              .getDistricts(
                                                                province: p,
                                                              )
                                                              .any(
                                                                (d) => repo
                                                                    .getMunicipalities(
                                                                      province:
                                                                          p,
                                                                      district:
                                                                          d,
                                                                    )
                                                                    .contains(
                                                                      municipality,
                                                                    ),
                                                              ),
                                                          orElse: () => '',
                                                        ),
                                                    district: filter.selectedDistricts!.firstWhere(
                                                      (d) => repo
                                                          .getMunicipalities(
                                                            province: filter
                                                                .selectedProvinces!
                                                                .firstWhere(
                                                                  (p) => repo
                                                                      .getDistricts(
                                                                        province:
                                                                            p,
                                                                      )
                                                                      .contains(
                                                                        d,
                                                                      ),
                                                                  orElse: () =>
                                                                      '',
                                                                ),
                                                            district: d,
                                                          )
                                                          .contains(
                                                            municipality,
                                                          ),
                                                      orElse: () => '',
                                                    ),
                                                    municipality: municipality,
                                                  )
                                                  .map(
                                                    (w) => {
                                                      'ward_no':
                                                          w['ward_no'] as int,
                                                      'municipality':
                                                          municipality,
                                                    },
                                                  ),
                                            )
                                            .toList()
                                          ..sort(
                                            (a, b) => (a['ward_no'] as int)
                                                .compareTo(b['ward_no'] as int),
                                          ),
                                    onChanged: (values) => ref
                                        .read(filterProvider.notifier)
                                        .setSelectedWards(
                                          values
                                              .map((v) => v['ward_no'] as int)
                                              .toList(),
                                        ),
                                    itemLabel: (v) =>
                                        '${v['ward_no']} - ${v['municipality']}',
                                  ),
                                // Multi-select Booths
                                if ((filter.selectedWards ?? []).isNotEmpty)
                                  _buildMultiSelect<String>(
                                    label: 'Booths (मतदान केन्द्रहरू)',
                                    icon: Icons.how_to_vote,
                                    selectedValues: filter.selectedBooths ?? [],
                                    allValues:
                                        filter.selectedWards!
                                            .expand(
                                              (ward) => repo
                                                  .getBooths(
                                                    province: filter.selectedProvinces!.firstWhere(
                                                      (p) => repo
                                                          .getDistricts(
                                                            province: p,
                                                          )
                                                          .any(
                                                            (d) => repo
                                                                .getMunicipalities(
                                                                  province: p,
                                                                  district: d,
                                                                )
                                                                .any(
                                                                  (m) => repo
                                                                      .getWards(
                                                                        province:
                                                                            p,
                                                                        district:
                                                                            d,
                                                                        municipality:
                                                                            m,
                                                                      )
                                                                      .any(
                                                                        (w) =>
                                                                            (w['ward_no']
                                                                                as int?) ==
                                                                            ward,
                                                                      ),
                                                                ),
                                                          ),
                                                      orElse: () => '',
                                                    ),
                                                    district: filter.selectedDistricts!.firstWhere(
                                                      (d) => repo
                                                          .getMunicipalities(
                                                            province: filter
                                                                .selectedProvinces!
                                                                .first,
                                                            district: d,
                                                          )
                                                          .any(
                                                            (m) => repo
                                                                .getWards(
                                                                  province: filter
                                                                      .selectedProvinces!
                                                                      .first,
                                                                  district: d,
                                                                  municipality:
                                                                      m,
                                                                )
                                                                .any(
                                                                  (w) =>
                                                                      (w['ward_no']
                                                                          as int?) ==
                                                                      ward,
                                                                ),
                                                          ),
                                                      orElse: () => '',
                                                    ),
                                                    municipality: filter
                                                        .selectedMunicipalities!
                                                        .firstWhere(
                                                          (m) => repo
                                                              .getWards(
                                                                province: filter
                                                                    .selectedProvinces!
                                                                    .first,
                                                                district: filter
                                                                    .selectedDistricts!
                                                                    .first,
                                                                municipality: m,
                                                              )
                                                              .any(
                                                                (w) =>
                                                                    (w['ward_no']
                                                                        as int?) ==
                                                                    ward,
                                                              ),
                                                          orElse: () => '',
                                                        ),
                                                    wardNo: ward,
                                                  )
                                                  .map(
                                                    (b) =>
                                                        b['booth_code']
                                                            as String,
                                                  ),
                                            )
                                            .toSet()
                                            .toList()
                                          ..sort(),
                                    onChanged: (values) => ref
                                        .read(filterProvider.notifier)
                                        .setSelectedBooths(values),
                                  ),
                              ]
                            : [
                                const Text(
                                  'Select single values:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Single-select dropdowns
                                _buildDropdown<String>(
                                  label: 'Province (प्रदेश)',
                                  icon: Icons.public,
                                  value: filter.province,
                                  items: repo.getProvinces(),
                                  onChanged: ref
                                      .read(filterProvider.notifier)
                                      .setProvince,
                                ),
                                if (filter.province != null)
                                  _buildDropdown<String>(
                                    label: 'District (जिल्ला)',
                                    icon: Icons.location_city,
                                    value: filter.district,
                                    items: repo.getDistricts(
                                      province: filter.province!,
                                    ),
                                    onChanged: ref
                                        .read(filterProvider.notifier)
                                        .setDistrict,
                                  ),
                                if (filter.province != null &&
                                    filter.district != null)
                                  _buildDropdown<String>(
                                    label:
                                        'Municipality (नगरपालिका/गाउँपालिका)',
                                    icon: Icons.location_on,
                                    value: filter.municipality,
                                    items: repo.getMunicipalities(
                                      province: filter.province!,
                                      district: filter.district!,
                                    ),
                                    onChanged: ref
                                        .read(filterProvider.notifier)
                                        .setMunicipality,
                                  ),
                                if (filter.province != null &&
                                    filter.district != null &&
                                    filter.municipality != null)
                                  _buildDropdown<Map<String, dynamic>>(
                                    label: 'Ward No (वडा नं.)',
                                    icon: Icons.format_list_numbered,
                                    value: filter.wardNo != null
                                        ? repo
                                              .getWards(
                                                province: filter.province!,
                                                district: filter.district!,
                                                municipality:
                                                    filter.municipality!,
                                              )
                                              .firstWhere(
                                                (w) =>
                                                    w['ward_no'] ==
                                                    filter.wardNo,
                                                orElse: () => {
                                                  'ward_no': filter.wardNo,
                                                },
                                              )
                                        : null,
                                    items: repo.getWards(
                                      province: filter.province!,
                                      district: filter.district!,
                                      municipality: filter.municipality!,
                                    ),
                                    itemLabel: (w) =>
                                        '${w['ward_no']} - ${filter.municipality}',
                                    onChanged: (value) => ref
                                        .read(filterProvider.notifier)
                                        .setWardNo(value?['ward_no'] as int?),
                                  ),
                                if (filter.province != null &&
                                    filter.district != null &&
                                    filter.municipality != null &&
                                    filter.wardNo != null)
                                  _buildDropdown<Map<String, dynamic>>(
                                    label: 'Booth (मतदान केन्द्र)',
                                    icon: Icons.how_to_vote,
                                    value: filter.boothCode != null
                                        ? repo
                                              .getBooths(
                                                province: filter.province!,
                                                district: filter.district!,
                                                municipality:
                                                    filter.municipality!,
                                                wardNo: filter.wardNo!,
                                              )
                                              .firstWhere(
                                                (b) =>
                                                    b['booth_code'] ==
                                                    filter.boothCode,
                                                orElse: () => {
                                                  'booth_code':
                                                      filter.boothCode,
                                                },
                                              )
                                        : null,
                                    items: repo.getBooths(
                                      province: filter.province!,
                                      district: filter.district!,
                                      municipality: filter.municipality!,
                                      wardNo: filter.wardNo!,
                                    ),
                                    itemLabel: (b) =>
                                        '${b['booth_code']} - ${b['booth_name'] ?? 'Unknown'}',
                                    onChanged: (value) => ref
                                        .read(filterProvider.notifier)
                                        .setBoothCode(
                                          value?['booth_code'] as String?,
                                        ),
                                  ),
                              ],
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
                min: 16,
                max: 150,
                divisions: 82,
                labels: RangeLabels(
                  '${filter.minAge ?? 16}',
                  '${filter.maxAge ?? 150}',
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

              const SizedBox(height: 32),

              // Main category grouping
              Consumer(
                builder: (context, ref, child) {
                  final mainCategoriesAsync = ref.watch(mainCategoriesProvider);
                  return mainCategoriesAsync.when(
                    data: (categories) {
                      final categoryNames =
                          categories
                              .map((cat) => cat['Mname'] as String)
                              .toList()
                            ..add('Unrecognized');
                      return _buildDropdown<String>(
                        label: 'Main Group / Category (मुख्य समूह)',
                        icon: Icons.category,
                        value: filter.mainCategory,
                        items: categoryNames,
                        onChanged: ref
                            .read(filterProvider.notifier)
                            .setMainCategory,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading categories: $e'),
                  );
                },
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
                      final currentFilter = ref.read(filterProvider);
                      ref
                          .read(voterProvider.notifier)
                          .applyFiltersAndReload(currentFilter);
                      ref.invalidate(analyticsDataProvider);
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
    bool enabled = true,
  }) {
    // Ensure unique items to prevent dropdown errors
    final uniqueItems = items.toSet().toList();
    // Ensure value is valid, otherwise set to null
    T? effectiveValue = value;
    if (value != null && !uniqueItems.contains(value)) {
      effectiveValue = null;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T?>(
        value: effectiveValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All / सबै')),
          ...uniqueItems.map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(itemLabel?.call(e) ?? e.toString()),
            ),
          ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildMultiSelect<T>({
    required String label,
    required IconData icon,
    required List<T> selectedValues,
    required List<T> allValues,
    required ValueChanged<List<T>> onChanged,
    String Function(T)? itemLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await showDialog<List<T>>(
            context: context,
            builder: (context) {
              List<T> tempSelected = List.from(selectedValues);
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text(label),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: allValues.map((value) {
                          final isSelected = tempSelected.contains(value);
                          return CheckboxListTile(
                            title: Text(
                              itemLabel?.call(value) ?? value.toString(),
                            ),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  tempSelected.add(value);
                                } else {
                                  tempSelected.remove(value);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, tempSelected),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            },
          );
          if (result != null) {
            onChanged(result);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            selectedValues.isEmpty
                ? 'Select...'
                : selectedValues.length == 1
                ? (itemLabel?.call(selectedValues.first) ??
                      selectedValues.first.toString())
                : '${selectedValues.length} selected',
          ),
        ),
      ),
    );
  }
}
