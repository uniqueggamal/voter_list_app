import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voter_provider.dart';
import '../services/export_service.dart';

class ExportButtonWidget extends ConsumerStatefulWidget {
  const ExportButtonWidget({super.key});

  @override
  ConsumerState<ExportButtonWidget> createState() => _ExportButtonWidgetState();
}

class _ExportButtonWidgetState extends ConsumerState<ExportButtonWidget> {
  final Map<String, String> exportFields = {
    'voter_id': 'Voter ID',
    'name': 'Name',
    'name_nepali': 'नाम (नेपाली)',
    'age': 'Age',
    'gender': 'Gender',
    'spouse_name': 'Spouse Name',
    'parent_name': 'Parent Name',
    'booth': 'Booth',
    'ward_no': 'Ward No',
    'municipality': 'Municipality',
    'district': 'District',
    'province': 'Province',
  };

  late Map<String, bool> selectedFields;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    selectedFields = {
      for (final key in exportFields.keys)
        key: key == 'voter_id' || key == 'name',
    };
  }

  @override
  Widget build(BuildContext context) {
    final totalCountAsync = ref.watch(totalVoterCountProvider);

    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: 'Export Filtered Data',
      onPressed: totalCountAsync.maybeWhen(
        data: (count) =>
            () => _showExportDialog(context, count),
        orElse: () => null,
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context, int totalCount) async {
    if (!mounted) return;

    final startController = TextEditingController(text: '1');
    final endController = TextEditingController(text: totalCount.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Filtered Voters'),
          content: SizedBox(
            width: 500,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total filtered voters: $totalCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Range selection
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Start (1-based)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'End',
                            hintText: 'Max: $totalCount',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Field selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Fields to Export',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              selectedFields.updateAll((_, __) => true);
                            }),
                            child: const Text('Select All'),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              selectedFields.updateAll((_, __) => false);
                            }),
                            child: const Text('Deselect All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),

                  ...exportFields.entries.map(
                    (entry) => CheckboxListTile(
                      dense: true,
                      title: Text(entry.value),
                      value: selectedFields[entry.key]!,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedFields[entry.key] = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.table_chart),
              label: const Text('Export to Excel'),
              onPressed: _isExporting
                  ? null
                  : () => _exportData(
                      dialogContext,
                      startController.text,
                      endController.text,
                      totalCount,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(
    BuildContext dialogContext,
    String startText,
    String endText,
    int totalCount,
  ) async {
    final start = int.tryParse(startText) ?? 1;
    final end = int.tryParse(endText) ?? totalCount;

    if (start < 1 || end < start || end > totalCount) {
      _showSnackBar(dialogContext, 'Invalid range: 1 to $totalCount');
      return;
    }

    final selectedKeys = selectedFields.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedKeys.isEmpty) {
      _showSnackBar(dialogContext, 'Please select at least one field');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final provider = ref.read(voterProvider.notifier);
      final exportService = ExportService();

      final voters = await provider.getVotersForExport(start, end);

      if (!dialogContext.mounted) return;

      await exportService.exportToExcel(voters, selectedKeys);

      if (!dialogContext.mounted) return;

      _showSnackBar(
        dialogContext,
        'Export completed! (${voters.length} voters)',
      );
      Navigator.pop(dialogContext);
    } catch (e) {
      if (!dialogContext.mounted) return;
      _showSnackBar(dialogContext, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
