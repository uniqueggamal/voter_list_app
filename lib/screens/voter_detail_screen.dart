import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/voter.dart';

class VoterDetailScreen extends StatefulWidget {
  final Voter voter;

  const VoterDetailScreen({super.key, required this.voter});

  @override
  State<VoterDetailScreen> createState() => _VoterDetailScreenState();
}

class _VoterDetailScreenState extends State<VoterDetailScreen> {
  late TextEditingController nameController;
  late TextEditingController englishNameController;
  late TextEditingController voterIdController;
  late TextEditingController ageController;
  late TextEditingController genderController;
  late TextEditingController fatherNameController;
  late TextEditingController motherNameController;
  late TextEditingController wardNoController;
  late TextEditingController boothCodeController;
  late TextEditingController boothNameController;
  late TextEditingController municipalityController;
  late TextEditingController districtController;
  late TextEditingController provinceController;
  late TextEditingController phoneController;
  late TextEditingController descriptionController;
  late TextEditingController groupingController;
  late TextEditingController categoryController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.voter.nameNepali ?? widget.voter.nameEnglish ?? '',
    );
    englishNameController = TextEditingController(
      text: widget.voter.nameEnglish ?? '',
    );
    voterIdController = TextEditingController(text: widget.voter.voterId);
    ageController = TextEditingController(
      text: widget.voter.age?.toString() ?? '',
    );
    genderController = TextEditingController(
      text: widget.voter.gender == 'M'
          ? 'पुरुष'
          : widget.voter.gender == 'F'
          ? 'महिला'
          : widget.voter.gender,
    );
    fatherNameController = TextEditingController(
      text: widget.voter.fatherName ?? '',
    );
    motherNameController = TextEditingController(
      text: widget.voter.motherName ?? '',
    );
    wardNoController = TextEditingController(
      text: widget.voter.wardNo.toString(),
    );
    boothCodeController = TextEditingController(text: widget.voter.boothCode);
    boothNameController = TextEditingController(text: widget.voter.boothName);
    municipalityController = TextEditingController(
      text: widget.voter.municipality,
    );
    districtController = TextEditingController(text: widget.voter.district);
    provinceController = TextEditingController(text: widget.voter.province);
    phoneController = TextEditingController(text: ''); // Placeholder
    descriptionController = TextEditingController(text: ''); // Placeholder
    groupingController = TextEditingController(text: ''); // Placeholder
    categoryController = TextEditingController(text: ''); // Placeholder
  }

  @override
  void dispose() {
    nameController.dispose();
    englishNameController.dispose();
    voterIdController.dispose();
    ageController.dispose();
    genderController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    wardNoController.dispose();
    boothCodeController.dispose();
    boothNameController.dispose();
    municipalityController.dispose();
    districtController.dispose();
    provinceController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    groupingController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.voter.nameNepali ?? widget.voter.nameEnglish ?? 'मतदाता विवरण',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Gender Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: widget.voter.gender == 'M'
                  ? Colors.blue
                  : Colors.pink,
              child: Text(
                widget.voter.gender,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              nameController.text.isNotEmpty
                  ? nameController.text
                  : 'नाम उपलब्ध छैन',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Voter ID
            Text(
              'मतदाता नं.: ${voterIdController.text}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Details Cards
            _buildEditableDetailCard('नाम', nameController),
            _buildEditableDetailCard('Name (English)', englishNameController),
            _buildEditableDetailCard('मतदाता नं.', voterIdController),
            _buildEditableDetailCard('उमेर', ageController),
            _buildEditableDetailCard('लिङ्ग', genderController),
            _buildEditableDetailCard('बुवा नाम', fatherNameController),
            _buildEditableDetailCard('आमा नाम', motherNameController),
            _buildEditableDetailCard('वडा नं.', wardNoController),
            _buildEditableDetailCard('बुथ कोड', boothCodeController),
            _buildEditableDetailCard('बुथ नाम', boothNameController),
            _buildEditableDetailCard('नगरपालिका', municipalityController),
            _buildEditableDetailCard('जिल्ला', districtController),
            _buildEditableDetailCard('प्रदेश', provinceController),
            _buildEditableDetailCard('फोन', phoneController),
            _buildEditableDetailCard('टिप्पणीहरू', descriptionController),
            _buildEditableDetailCard('समूह/वर्गीकरण', groupingController),
            _buildEditableDetailCard('वर्ग', categoryController),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('कल गर्नुहोस्'),
                  onPressed: () {
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
      ),
    );
  }

  Widget _buildEditableDetailCard(
    String label,
    TextEditingController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: controller.text));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$label copied')));
              },
              tooltip: 'Copy $label',
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    // TODO: Implement save logic to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved (placeholder)')),
    );
  }
}
