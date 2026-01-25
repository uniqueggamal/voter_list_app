import 'package:flutter/material.dart';
import '../services/export_service.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final Map<String, String> exportFields = {
    'voter_no': 'Voter No',
    'name': 'Name (Nepali)',
    'name_en': 'Name (English)',
    'age': 'Age',
    'gender': 'Gender',
    'parents_name': 'Parents Name',
    'spouse_name_np': 'Spouse Name',
    'province': 'Province',
    'district_name': 'District',
    'municipality_name': 'Municipality',
    'ward_no': 'Ward No',
    'booth_name': 'Booth Name',
    'main_category': 'Main Category',
    'sub_category': 'Sub Category',
    'tags': 'Tags',
    'phone_no': 'Phone No',
    'description': 'Description',
  };

  late Map<String, bool> selectedFields;
  bool _isExporting = false;
  final TextEditingController startIndexController = TextEditingController(
    text: '1',
  );
  final TextEditingController endIndexController = TextEditingController();
  final TextEditingController filenameController = TextEditingController(
    text: 'voter_export',
  );

  @override
  void initState() {
    super.initState();
    selectedFields = {
      for (final key in exportFields.keys)
        key: key == 'voter_no' || key == 'name',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Voter Data'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export Range',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startIndexController,
                      decoration: const InputDecoration(
                        labelText: 'Start Index (1-based)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endIndexController,
                      decoration: const InputDecoration(
                        labelText: 'End Index (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: filenameController,
                decoration: const InputDecoration(
                  labelText: 'Filename (without extension)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Fields to Export',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ...exportFields.entries.map(
                (entry) => CheckboxListTile(
                  dense: true,
                  title: Text(entry.value),
                  value: selectedFields[entry.key]!,
                  onChanged: (value) {
                    setState(() {
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
          onPressed: () => Navigator.pop(context),
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
          onPressed: _isExporting ? null : _exportData,
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    final selectedKeys = selectedFields.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one field')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final startIndex = int.tryParse(startIndexController.text);
      final endIndex = endIndexController.text.isNotEmpty
          ? int.tryParse(endIndexController.text)
          : null;

      if (startIndex != null && startIndex < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start index must be 1 or greater')),
        );
        return;
      }

      if (endIndex != null && endIndex < startIndex!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'End index must be greater than or equal to start index',
            ),
          ),
        );
        return;
      }

      final exportService = ExportService();
      await exportService.exportToExcelWithFields(
        context,
        exportFields,
        selectedKeys,
        startIndex: startIndex,
        endIndex: endIndex,
        filename: filenameController.text.isNotEmpty
            ? filenameController.text
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
