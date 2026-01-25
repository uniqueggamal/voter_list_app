import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voter.dart';
import '../helpers/database_helper.dart';
import '../widgets/voter_tags_dialog.dart';
import '../providers/voter_tags_provider.dart';
import '../providers/voter_provider.dart';
import '../providers/filter_provider.dart';
import '../models/tag.dart';
import '../services/voter_edit_service.dart';

class VoterDetailScreen extends ConsumerStatefulWidget {
  final Voter voter;

  const VoterDetailScreen({super.key, required this.voter});

  @override
  ConsumerState<VoterDetailScreen> createState() => _VoterDetailScreenState();
}

class _VoterDetailScreenState extends ConsumerState<VoterDetailScreen> {
  Voter? _loadedVoter;
  bool _isLoading = true;
  TextEditingController? nameController;
  TextEditingController? englishNameController;
  TextEditingController? voterIdController;
  TextEditingController? ageController;
  TextEditingController? genderController;
  TextEditingController? parentsNameController;
  TextEditingController? wardNoController;
  TextEditingController? boothNameController;
  TextEditingController? municipalityController;
  TextEditingController? districtController;
  TextEditingController? provinceController;
  TextEditingController? phoneController;
  TextEditingController? descriptionController;
  TextEditingController? groupingController;
  TextEditingController? categoryController;
  TextEditingController? mainCategoryController;
  TextEditingController? subCategoryController;

  @override
  void initState() {
    super.initState();
    _createControllers();
    _initializeControllers(widget.voter);
    _loadVoterDetails();
  }

  void _createControllers() {
    nameController = TextEditingController();
    englishNameController = TextEditingController();
    voterIdController = TextEditingController();
    ageController = TextEditingController();
    genderController = TextEditingController();
    parentsNameController = TextEditingController();
    wardNoController = TextEditingController();
    boothNameController = TextEditingController();
    municipalityController = TextEditingController();
    districtController = TextEditingController();
    provinceController = TextEditingController();
    phoneController = TextEditingController();
    descriptionController = TextEditingController();
    groupingController = TextEditingController();
    categoryController = TextEditingController();
    mainCategoryController = TextEditingController();
    subCategoryController = TextEditingController();
  }

  Future<void> _loadVoterDetails() async {
    try {
      final voterData = await DatabaseHelper.instance.getVoter(widget.voter.id);
      debugPrint('Voter data from DB: $voterData');
      if (voterData != null) {
        var loadedVoter = Voter.fromMap(voterData);
        debugPrint('Loaded voter: ${loadedVoter.toString()}');
        debugPrint('Main category: ${loadedVoter.mainCategory}');
        debugPrint('Sub category: ${loadedVoter.subCategory}');

        // Load additional details from voterdetails table
        final voterDetails = await DatabaseHelper.instance
            .getVoterDetailByVoterId(widget.voter.id);
        if (voterDetails != null) {
          loadedVoter = loadedVoter.copyWith(
            phone: voterDetails['phone'] as String?,
            description: voterDetails['description'] as String?,
            nameEnglish:
                (voterDetails['name_en'] as String?)?.isNotEmpty == true
                ? voterDetails['name_en'] as String
                : loadedVoter.nameEnglish,
          );
        }

        if (mounted) {
          setState(() {
            _loadedVoter = loadedVoter;
            _isLoading = false;
          });
          _initializeControllers(loadedVoter);
        }
      } else {
        debugPrint('No voter data found for id: ${widget.voter.id}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _initializeControllers(widget.voter);
        }
      }
    } catch (e) {
      debugPrint('Error loading voter details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _initializeControllers(widget.voter);
      }
    }
  }

  void _initializeControllers(Voter voter) {
    nameController?.text = voter.nameNepali ?? voter.nameEnglish ?? '';
    englishNameController?.text = voter.nameEnglish ?? '';
    voterIdController?.text = voter.voterId;
    ageController?.text = voter.age?.toString() ?? '';
    genderController?.text = voter.gender == 'M'
        ? 'पुरुष'
        : voter.gender == 'F'
        ? 'महिला'
        : voter.gender;
    parentsNameController?.text = voter.parentname ?? '';
    wardNoController?.text = voter.wardNo.toString();
    boothNameController?.text = voter.boothName;
    municipalityController?.text = voter.municipality;
    districtController?.text = voter.district;
    provinceController?.text = voter.province;
    phoneController?.text = voter.phone ?? '';
    descriptionController?.text = voter.description ?? '';
    groupingController?.text = ''; // Placeholder
    categoryController?.text = ''; // Placeholder
    mainCategoryController?.text = voter.mainCategory ?? '';
    subCategoryController?.text = voter.subCategory ?? '';
  }

  @override
  void dispose() {
    nameController?.dispose();
    englishNameController?.dispose();
    voterIdController?.dispose();
    ageController?.dispose();
    genderController?.dispose();
    parentsNameController?.dispose();
    wardNoController?.dispose();
    boothNameController?.dispose();
    municipalityController?.dispose();
    districtController?.dispose();
    provinceController?.dispose();
    phoneController?.dispose();
    descriptionController?.dispose();
    groupingController?.dispose();
    categoryController?.dispose();
    mainCategoryController?.dispose();
    subCategoryController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayVoter = _loadedVoter ?? widget.voter;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('मतदाता विवरण')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayVoter.nameNepali ?? displayVoter.nameEnglish ?? 'मतदाता विवरण',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllDetails,
            tooltip: 'Copy All Details',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Gender Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _getGenderColor(displayVoter.gender),
                child: Icon(
                  _getGenderIcon(displayVoter.gender),
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            // Details Cards
            if (nameController != null)
              _buildEditableDetailCard('नाम', nameController),
            if (englishNameController != null)
              _buildEditableDetailCard('Name (English)', englishNameController),
            if (voterIdController != null)
              _buildEditableDetailCard('मतदाता नं.', voterIdController),
            if (ageController != null)
              _buildEditableDetailCard('उमेर', ageController),
            if (genderController != null)
              _buildEditableDetailCard('लिङ्ग', genderController),
            if (parentsNameController != null)
              _buildEditableDetailCard('बुवा/आमा नाम', parentsNameController),
            if (wardNoController != null)
              _buildEditableDetailCard('वडा नं.', wardNoController),
            if (boothNameController != null)
              _buildEditableDetailCard('बुथ नाम', boothNameController),
            if (municipalityController != null)
              _buildEditableDetailCard('नगरपालिका', municipalityController),
            if (districtController != null)
              _buildEditableDetailCard('जिल्ला', districtController),
            if (provinceController != null)
              _buildEditableDetailCard('प्रदेश', provinceController),
            if (phoneController != null)
              _buildEditableDetailCard('फोन', phoneController),
            if (descriptionController != null)
              _buildEditableDetailCard('टिप्पणीहरू', descriptionController),
            if (mainCategoryController != null)
              _buildEditableDetailCard('मुख्य वर्ग', mainCategoryController),
            if (subCategoryController != null)
              _buildEditableDetailCard('उप वर्ग', subCategoryController),
            const SizedBox(height: 24),
            // Tags Card
            _buildTagsCard(displayVoter.id),
            const SizedBox(height: 24),
            // Save Edit Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Save Edit'),
                onPressed: () async {
                  await _saveChanges();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableDetailCard(
    String label,
    TextEditingController? controller,
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
                Clipboard.setData(ClipboardData(text: controller?.text ?? ''));
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

  void _copyAllDetails() {
    final details = <String>[];

    // Add non-empty details
    if (nameController?.text.isNotEmpty ?? false) {
      details.add('नाम: ${nameController!.text}');
    }
    if (englishNameController?.text.isNotEmpty ?? false) {
      details.add('Name (English): ${englishNameController!.text}');
    }
    if (voterIdController?.text.isNotEmpty ?? false) {
      details.add('मतदाता नं.: ${voterIdController!.text}');
    }
    if (ageController?.text.isNotEmpty ?? false) {
      details.add('उमेर: ${ageController!.text}');
    }
    if (genderController?.text.isNotEmpty ?? false) {
      details.add('लिङ्ग: ${genderController!.text}');
    }
    if (parentsNameController?.text.isNotEmpty ?? false) {
      details.add('बुवा/आमा नाम: ${parentsNameController!.text}');
    }
    if (wardNoController?.text.isNotEmpty ?? false) {
      details.add('वडा नं.: ${wardNoController!.text}');
    }
    if (boothNameController?.text.isNotEmpty ?? false) {
      details.add('बुथ नाम: ${boothNameController!.text}');
    }
    if (municipalityController?.text.isNotEmpty ?? false) {
      details.add('नगरपालिका: ${municipalityController!.text}');
    }
    if (districtController?.text.isNotEmpty ?? false) {
      details.add('जिल्ला: ${districtController!.text}');
    }
    if (provinceController?.text.isNotEmpty ?? false) {
      details.add('प्रदेश: ${provinceController!.text}');
    }
    if (phoneController?.text.isNotEmpty ?? false) {
      details.add('फोन: ${phoneController!.text}');
    }
    if (descriptionController?.text.isNotEmpty ?? false) {
      details.add('टिप्पणीहरू: ${descriptionController!.text}');
    }
    if (mainCategoryController?.text.isNotEmpty ?? false) {
      details.add('मुख्य वर्ग: ${mainCategoryController!.text}');
    }
    if (subCategoryController?.text.isNotEmpty ?? false) {
      details.add('उप वर्ग: ${subCategoryController!.text}');
    }

    if (details.isNotEmpty) {
      final allDetails = details.join('\n');
      Clipboard.setData(ClipboardData(text: allDetails));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All details copied to clipboard')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No details to copy')));
    }
  }

  Future<void> _saveChanges() async {
    final displayVoter = _loadedVoter ?? widget.voter;
    final validationError = VoterEditService.instance.validateVoterData(
      phone: phoneController?.text,
      age: ageController?.text,
      wardNo: wardNoController?.text,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final success = await VoterEditService.instance.saveVoterEdits(
      voterId: displayVoter.id,
      voterNo: displayVoter.voterId,
      phone: phoneController?.text.trim(),
      description: descriptionController?.text.trim(),
      name: nameController?.text.isNotEmpty == true
          ? nameController!.text
          : null,
      englishName: englishNameController?.text.isNotEmpty == true
          ? englishNameController!.text
          : null,
      age: ageController?.text.isNotEmpty == true ? ageController!.text : null,
      gender: genderController?.text.isNotEmpty == true
          ? genderController!.text
          : null,
      parentsName: parentsNameController?.text.isNotEmpty == true
          ? parentsNameController!.text
          : null,
      wardNo: wardNoController?.text.isNotEmpty == true
          ? wardNoController!.text
          : null,
      boothName: boothNameController?.text.isNotEmpty == true
          ? boothNameController!.text
          : null,
      municipality: municipalityController?.text.isNotEmpty == true
          ? municipalityController!.text
          : null,
      district: districtController?.text.isNotEmpty == true
          ? districtController!.text
          : null,
      province: provinceController?.text.isNotEmpty == true
          ? provinceController!.text
          : null,
      mainCategory: mainCategoryController?.text.isNotEmpty == true
          ? mainCategoryController!.text
          : null,
      subCategory: subCategoryController?.text.isNotEmpty == true
          ? subCategoryController!.text
          : null,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
      // Reload the voter details to reflect the changes
      await _loadVoterDetails();
      // Update the cached voter data with the new information
      final baseVoter = _loadedVoter ?? widget.voter;
      final updatedVoter = Voter(
        id: baseVoter.id,
        voterId: voterIdController?.text ?? baseVoter.voterId,
        nameNepali: nameController?.text.isNotEmpty == true
            ? nameController!.text
            : baseVoter.nameNepali,
        nameEnglish: englishNameController?.text.isNotEmpty == true
            ? englishNameController!.text
            : baseVoter.nameEnglish,
        age: ageController?.text.isNotEmpty == true
            ? int.tryParse(ageController!.text)
            : baseVoter.age,
        gender: genderController?.text.isNotEmpty == true
            ? genderController!.text
            : baseVoter.gender,
        parentname: parentsNameController?.text.isNotEmpty == true
            ? parentsNameController!.text
            : baseVoter.parentname,
        wardNo: wardNoController?.text.isNotEmpty == true
            ? int.tryParse(wardNoController!.text) ?? baseVoter.wardNo
            : baseVoter.wardNo,
        boothName: boothNameController?.text.isNotEmpty == true
            ? boothNameController!.text
            : baseVoter.boothName,
        municipality: municipalityController?.text.isNotEmpty == true
            ? municipalityController!.text
            : baseVoter.municipality,
        district: districtController?.text.isNotEmpty == true
            ? districtController!.text
            : baseVoter.district,
        provinceId: baseVoter.provinceId,
        province: provinceController?.text.isNotEmpty == true
            ? provinceController!.text
            : baseVoter.province,
        districtId: baseVoter.districtId,
        municipalityId: baseVoter.municipalityId,
        municipalityCode: baseVoter.municipalityCode,
        boothCode: baseVoter.boothCode,
        mainCategory: mainCategoryController?.text.isNotEmpty == true
            ? mainCategoryController!.text
            : baseVoter.mainCategory,
        subCategory: subCategoryController?.text.isNotEmpty == true
            ? subCategoryController!.text
            : baseVoter.subCategory,
        phone: phoneController?.text.isNotEmpty == true
            ? phoneController!.text
            : baseVoter.phone,
        description: descriptionController?.text.isNotEmpty == true
            ? descriptionController!.text
            : baseVoter.description,
      );
      ref.read(voterProvider.notifier).updateVoterInCache(updatedVoter);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save changes')));
    }
  }

  Color _getGenderColor(String? gender) {
    if (gender == null || gender.trim().isEmpty) {
      return Colors.grey;
    }

    final normalizedGender = gender.trim().toLowerCase();

    // Check for female
    if (normalizedGender == 'f' ||
        normalizedGender == 'female' ||
        normalizedGender.contains('female') ||
        normalizedGender.contains('महिला') ||
        normalizedGender == 'महि' ||
        normalizedGender == 'फ' ||
        normalizedGender == 'female') {
      return Colors.pink;
    }

    // Check for male
    if (normalizedGender == 'm' ||
        normalizedGender == 'male' ||
        normalizedGender.contains('male') ||
        normalizedGender.contains('पुरुष') ||
        normalizedGender == 'पु' ||
        normalizedGender == 'म' ||
        normalizedGender == 'male') {
      return Colors.blue;
    }

    // Default fallback
    return Colors.grey;
  }

  IconData _getGenderIcon(String? gender) {
    // Use head-only icon for all genders
    return Icons.account_circle;
  }

  String _getGenderText(String? gender) {
    if (gender == null || gender.trim().isEmpty) {
      return 'Unknown';
    }

    final normalizedGender = gender.trim().toLowerCase();

    // Check for female
    if (normalizedGender == 'f' ||
        normalizedGender == 'female' ||
        normalizedGender.contains('female') ||
        normalizedGender.contains('महिला') ||
        normalizedGender == 'महि' ||
        normalizedGender == 'फ' ||
        normalizedGender == 'female') {
      return 'Female';
    }

    // Check for male
    if (normalizedGender == 'm' ||
        normalizedGender == 'male' ||
        normalizedGender.contains('male') ||
        normalizedGender.contains('पुरुष') ||
        normalizedGender == 'पु' ||
        normalizedGender == 'म' ||
        normalizedGender == 'male') {
      return 'Male';
    }

    // Default fallback
    return 'Unknown';
  }

  Widget _buildTagsCard(int voterId) {
    return Consumer(
      builder: (context, ref, child) {
        final voterTags = ref.watch(voterTagsProvider(voterId));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Tags:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              VoterTagsDialog(voterId: voterId),
                        );
                      },
                      tooltip: 'Add Tag',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (voterTags.isEmpty)
                  const Text(
                    'No tags assigned',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: voterTags.map((tag) {
                      return Chip(
                        label: Text(
                          tag.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Color(
                          int.parse(tag.color.replaceFirst('#', '0xFF')),
                        ).withOpacity(0.2),
                        deleteIcon: const Icon(Icons.remove, size: 16),
                        onDeleted: () async {
                          await ref
                              .read(voterTagsProvider(voterId).notifier)
                              .removeTag(tag.id);
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
