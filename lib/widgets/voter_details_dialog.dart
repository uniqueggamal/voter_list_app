import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          data: (details) => _buildDetailsContent(context, ref, details),
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

  Widget _buildDetailsContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> details,
  ) {
    if (details.isEmpty) {
      return const Center(
        child: Text(
          'कुनै विवरण फेला परेन',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final name =
        details['name_np']?.toString() ??
        details['name']?.toString() ??
        'नाम उपलब्ध छैन';
    final voterId =
        details['voter_no']?.toString() ?? details['voterId']?.toString() ?? '';
    final gender = details['gender']?.toString() ?? '';
    final age = details['age']?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gender Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: gender == 'M' ? Colors.blue : Colors.pink,
            child: Text(
              gender,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Voter ID with copy
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ID: $voterId',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: voterId));
                  // Show snackbar, but since it's dialog, perhaps not
                },
                tooltip: 'Copy Voter ID',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Details Cards
          _buildDetailCard('नाम', name),
          _buildDetailCard('मतदाता नं.', voterId),
          _buildDetailCard('उमेर', age),
          _buildDetailCard(
            'लिङ्ग',
            gender == 'M'
                ? 'पुरुष'
                : gender == 'F'
                ? 'महिला'
                : gender,
          ),
          if (details['parent_name_np']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'बुवा/आमा नाम',
              details['parent_name_np'].toString(),
            ),
          if (details['spouse_name_np']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'श्रीमान्/श्रीमती नाम',
              details['spouse_name_np'].toString(),
            ),
          if (details['ward_no']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'वडा नं.',
              details['ward_no'].toString(),
              copyable: true,
            ),
          if (details['booth_code']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'बुथ कोड',
              details['booth_code'].toString(),
              copyable: true,
            ),
          if (details['province']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'प्रदेश',
              details['province'].toString(),
              copyable: true,
            ),
          if (details['district']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'जिल्ला',
              details['district'].toString(),
              copyable: true,
            ),
          if (details['municipality']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'नगरपालिका',
              details['municipality'].toString(),
              copyable: true,
            ),
          if (details['boothName']?.toString().isNotEmpty ?? false)
            _buildDetailCard(
              'बुथ नाम',
              details['boothName'].toString(),
              copyable: true,
            ),
          // Phone and Description
          _buildDetailCard('फोन', details['phone']?.toString() ?? ''),
          _buildDetailCard(
            'टिप्पणीहरू',
            details['description']?.toString() ?? '',
          ),
          if (details['name_en']?.toString().isNotEmpty ?? false)
            _buildDetailCard('Name (English)', details['name_en'].toString()),
          _buildDetailCard('समूह/वर्गीकरण', 'आउँदैछ...'),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text('कल गर्नुहोस्'),
                onPressed: () {
                  // Placeholder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call feature coming soon')),
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('सन्देश पठाउनुहोस्'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message feature coming soon'),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('सम्पादन गर्नुहोस्'),
                onPressed: () => _showEditDialog(context, ref, details),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, {bool copyable = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
            if (copyable && value.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                },
                tooltip: 'Copy $label',
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> details,
  ) {
    final phoneController = TextEditingController(
      text: details['phone']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: details['description']?.toString() ?? '',
    );
    final nameEnController = TextEditingController(
      text: details['name_en']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('सम्पादन गर्नुहोस्'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'फोन'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'टिप्पणीहरू'),
                maxLines: 3,
              ),
              TextField(
                controller: nameEnController,
                decoration: const InputDecoration(labelText: 'Name (English)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('रद्द गर्नुहोस्'),
            ),
            ElevatedButton(
              onPressed: () async {
                final dbHelper = DatabaseHelper.instance;
                final Map<String, dynamic> data = {
                  'phone': phoneController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'name_en': nameEnController.text.trim(),
                };

                // Update the voter details record using the correct voter ID
                final int voterIdToUpdate = voterId;
                final result = await dbHelper.updateVoterDetails(
                  voterIdToUpdate,
                  data,
                );

                if (result > 0) {
                  // Refresh the provider
                  ref.refresh(voterDetailsProvider(voterId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('विवरण अपडेट गरियो')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('अपडेट गर्न सकिएन')),
                  );
                }
              },
              child: const Text('सुरक्षित गर्नुहोस्'),
            ),
          ],
        );
      },
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
  if (voterMap != null) {
    // Fetch additional details from voterdetails table
    final voterDetails = await dbHelper.getVoterDetailByVoterId(voterId);
    if (voterDetails != null) {
      voterMap.addAll(voterDetails);
    } else {
      // If no voterdetails entry, initialize with empty values
      voterMap['phone'] = '';
      voterMap['description'] = '';
    }
  }
  return voterMap ?? {};
});
