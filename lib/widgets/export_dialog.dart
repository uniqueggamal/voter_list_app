import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../providers/voter_provider.dart';
import '../providers/filter_provider.dart';
import '../models/voter.dart';

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  final _startIndexController = TextEditingController(text: '1');
  final _endIndexController = TextEditingController();
  bool _exportCurrentSearch = true;
  bool _includeAllFilters = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Set default end index to total count or 1000
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEndIndex();
    });
  }

  @override
  void dispose() {
    _startIndexController.dispose();
    _endIndexController.dispose();
    super.dispose();
  }

  Future<void> _updateEndIndex() async {
    final totalCountAsync = ref.read(totalVoterCountProvider);
    totalCountAsync.whenData((total) {
      final endIndex = total > 1000 ? 1000 : total;
      _endIndexController.text = endIndex.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCountAsync = ref.watch(totalVoterCountProvider);

    return AlertDialog(
      title: const Text('Export Voters to Excel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index range
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startIndexController,
                    decoration: const InputDecoration(
                      labelText: 'Start Index',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endIndexController,
                    decoration: InputDecoration(
                      labelText: 'End Index',
                      border: const OutlineInputBorder(),
                      hintText: totalCountAsync.maybeWhen(
                        data: (total) => 'Max: $total',
                        orElse: () => 'Max: ?',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options
            CheckboxListTile(
              title: const Text('Export only current search results'),
              subtitle: const Text(
                'If unchecked, exports all voters matching filters',
              ),
              value: _exportCurrentSearch,
              onChanged: (value) =>
                  setState(() => _exportCurrentSearch = value ?? true),
            ),
            CheckboxListTile(
              title: const Text('Include all filters'),
              subtitle: const Text('Apply current filter settings'),
              value: _includeAllFilters,
              onChanged: (value) =>
                  setState(() => _includeAllFilters = value ?? true),
            ),

            const SizedBox(height: 16),
            const Text(
              'Columns: Voter ID, Name (Nepali), Age, Gender, District, Municipality, Ward, etc.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportData,
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export to Excel'),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final startIndex = int.tryParse(_startIndexController.text) ?? 1;
      final endIndex = int.tryParse(_endIndexController.text) ?? 1000;

      // Get voters based on current state
      List<Voter> voters;
      if (_exportCurrentSearch) {
        // Export current displayed voters
        final voterState = ref.read(voterProvider);
        voters = voterState.voters;
      } else {
        // Export all matching filters
        final filter = _includeAllFilters
            ? ref.read(filterProvider)
            : const FilterState();
        voters = await ref
            .read(voterProvider.notifier)
            .getVotersForExport(filter: filter);
      }

      // Apply index range
      final start = (startIndex - 1).clamp(0, voters.length);
      final end = endIndex.clamp(start, voters.length);
      final exportVoters = voters.sublist(start, end);

      // Create Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Voters'];

      // Headers
      sheet.appendRow([
        TextCellValue('Voter ID'),
        TextCellValue('Name (Nepali)'),
        TextCellValue('Name (English)'),
        TextCellValue('Age'),
        TextCellValue('Gender'),
        TextCellValue('District'),
        TextCellValue('Municipality'),
        TextCellValue('Ward'),
        TextCellValue('Booth Code'),
        TextCellValue('Province'),
        TextCellValue('Father Name'),
        TextCellValue('Mother Name'),
        TextCellValue('Address'),
        TextCellValue('Citizenship No'),
      ]);

      // Data rows
      for (final voter in exportVoters) {
        sheet.appendRow([
          TextCellValue(voter.voterId ?? ''),
          TextCellValue(voter.nameNepali ?? ''),
          TextCellValue(voter.nameEnglish ?? ''),
          TextCellValue(voter.age?.toString() ?? ''),
          TextCellValue(voter.gender ?? ''),
          TextCellValue(voter.district ?? ''),
          TextCellValue(voter.municipality ?? ''),
          TextCellValue(voter.wardNo?.toString() ?? ''),
          TextCellValue(voter.boothCode ?? ''),
          TextCellValue(voter.province ?? ''),
          TextCellValue(voter.fatherName ?? ''),
          TextCellValue(voter.motherName ?? ''),
          TextCellValue(voter.address ?? ''),
          TextCellValue(voter.citizenshipNo ?? ''),
        ]);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'voters_export_${startIndex}_${endIndex}_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${exportVoters.length} voters to: ${file.path}',
            ),
          ),
        );

        // Open the file
        await OpenFile.open(file.path);
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
