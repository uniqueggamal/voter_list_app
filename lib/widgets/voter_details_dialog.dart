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
          data: (details) => _buildDetailsContent(context, details),
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
            _buildDetailCard('वडा नं.', details['ward_no'].toString()),
          if (details['booth_code']?.toString().isNotEmpty ?? false)
            _buildDetailCard('बुथ कोड', details['booth_code'].toString()),
          // Placeholders
          _buildDetailCard('फोन', 'आउँदैछ...'),
          _buildDetailCard('टिप्पणीहरू', 'आउँदैछ...'),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
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
          ],
        ),
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
