import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/database_helper.dart';
import '../providers/voter_provider.dart';

class VoterDetailsDialog extends ConsumerWidget {
  final int voterId;

  const VoterDetailsDialog({super.key, required this.voterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch a future provider for voter details
    final voterDetailsAsync = ref.watch(
      voterDetailsProvider(voterId), // ← see definition below
    );

    return AlertDialog(
      title: const Text('मतदाता विवरण'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
        child: voterDetailsAsync.when(
          data: (details) => _buildDetailsContent(details),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'विवरण लोड गर्न सकिएन\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('बन्द गर्नुहोस्'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  Widget _buildDetailsContent(Map<String, dynamic> details) {
    if (details.isEmpty) {
      return const Center(
        child: Text(
          'कुनै विवरण फेला परेन',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final fieldOrder = [
      {'key': 'name_np', 'label': 'नाम'},
      {'key': 'name', 'label': 'Name (English)'},
      {'key': 'voter_no', 'label': 'मतदाता नं.'},
      {'key': 'age', 'label': 'उमेर'},
      {'key': 'gender', 'label': 'लिङ्ग'},
      {'key': 'parent_name_np', 'label': 'बुवा/आमाको नाम'},
      {'key': 'spouse_name_np', 'label': 'पति/पत्नीको नाम'},
      {'key': 'province', 'label': 'प्रदेश'},
      {'key': 'district', 'label': 'जिल्ला'},
      {'key': 'municipality', 'label': 'नगरपालिका / गाउँपालिका'},
      {'key': 'ward_no', 'label': 'वडा नं.'},
      {'key': 'booth_name', 'label': 'मतदान केन्द्र'},
      {'key': 'booth_code', 'label': 'बूथ कोड'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: fieldOrder.map((field) {
          final key = field['key']!;
          final label = field['label']!;
          final value = details[key]?.toString();

          if (value == null || value.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    '$label :',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// New provider for async voter details (recommended pattern)
final voterDetailsProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  voterId,
) async {
  final dbHelper = DatabaseHelper.instance;
  final voterMap = await dbHelper.getVoterById(voterId);
  return voterMap ?? {};
});
