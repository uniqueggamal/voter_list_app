import 'package:flutter/material.dart';
import '../models/voter.dart';
import '../helpers/database_helper.dart';

class VoterEditService {
  static final VoterEditService _instance = VoterEditService._internal();
  static VoterEditService get instance => _instance;

  VoterEditService._internal();

  /// Saves the edited voter details directly to the main database
  /// Returns true if successful, false otherwise
  Future<bool> saveVoterEdits({
    required int voterId,
    required String voterNo,
    String? phone,
    String? description,
    String? name,
    String? englishName,
    String? age,
    String? gender,
    String? parentsName,
    String? wardNo,
    String? boothName,
    String? municipality,
    String? district,
    String? province,
    String? mainCategory,
    String? subCategory,
  }) async {
    try {
      // Prepare the data to update in the voter table
      // Only update fields that actually exist as columns in the voter table
      Map<String, dynamic> voterUpdateData = {};

      if (name != null && name.isNotEmpty) {
        voterUpdateData['name_np'] = name;
      }
      if (age != null && age.isNotEmpty) {
        voterUpdateData['age'] = int.tryParse(age);
      }
      if (gender != null && gender.isNotEmpty) {
        voterUpdateData['gender'] = gender;
      }
      if (parentsName != null && parentsName.isNotEmpty) {
        voterUpdateData['parent_name_np'] = parentsName;
      }

      // Note: booth_name, ward_no, municipality, district, province are joined from other tables
      // and cannot be updated directly in the voter table
      // Only fields that exist as direct columns in the voter table can be updated

      // Note: municipality, district, province are joined from other tables
      // and cannot be updated directly in the voter table

      // Update the voter record in the main database
      if (voterUpdateData.isNotEmpty) {
        int result = await DatabaseHelper.instance.updateVoter(
          voterId,
          voterUpdateData,
        );
        debugPrint('Updated $result voter records');
      }

      // Prepare the data to update in the categorized table
      Map<String, dynamic> categorizedUpdateData = {};

      if (mainCategory != null && mainCategory.isNotEmpty) {
        categorizedUpdateData['Mname'] = mainCategory;
      }
      if (subCategory != null && subCategory.isNotEmpty) {
        categorizedUpdateData['Sname'] = subCategory;
      }

      // Update or insert the categorized record
      if (categorizedUpdateData.isNotEmpty) {
        categorizedUpdateData['voter_no'] = voterNo;
        await DatabaseHelper.instance.insertOrUpdateCategorized(
          voterNo,
          categorizedUpdateData,
        );
      }

      // Prepare the data to update in the voterdetails table
      Map<String, dynamic> voterDetailsUpdateData = {};

      debugPrint('Phone to save: "$phone"');
      debugPrint('Description to save: "$description"');

      if (phone != null) {
        voterDetailsUpdateData['phone'] = phone;
      }
      if (description != null) {
        voterDetailsUpdateData['description'] = description;
      }

      debugPrint('VoterDetails update data: $voterDetailsUpdateData');

      // Update or insert the voterdetails record
      if (voterDetailsUpdateData.isNotEmpty) {
        int result = await DatabaseHelper.instance.updateVoterDetails(
          voterId,
          voterDetailsUpdateData,
        );
        debugPrint('Updated $result voterdetails records');
      } else {
        debugPrint('No voterdetails data to update');
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error saving voter edits: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Validates the input data before saving
  String? validateVoterData({String? phone, String? age, String? wardNo}) {
    // Validate phone number (optional, but if provided should be reasonable length)
    if (phone != null && phone.isNotEmpty) {
      if (phone.length < 7 || phone.length > 15) {
        return 'Phone number should be between 7-15 digits';
      }
      // Check if phone contains only digits, spaces, hyphens, plus signs
      final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
      if (!phoneRegex.hasMatch(phone)) {
        return 'Phone number contains invalid characters';
      }
    }

    // Validate age (optional, but if provided should be reasonable)
    if (age != null && age.isNotEmpty) {
      final ageNum = int.tryParse(age);
      if (ageNum == null) {
        return 'Age must be a valid number';
      }
      if (ageNum < 18 || ageNum > 120) {
        return 'Age should be between 18-120';
      }
    }

    // Validate ward number (optional, but if provided should be positive)
    if (wardNo != null && wardNo.isNotEmpty) {
      final wardNum = int.tryParse(wardNo);
      if (wardNum == null) {
        return 'Ward number must be a valid number';
      }
      if (wardNum <= 0) {
        return 'Ward number must be positive';
      }
    }

    return null; // No validation errors
  }
}
