import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_repository.dart';

final locationRepoProvider = FutureProvider<LocationRepository>((ref) async {
  return LocationRepository.loadFromAsset('assets/location_data.json');
});

class FilterState {
  final String? province;
  final String? district;
  final String? municipality;
  final int? wardNo;
  final String? boothCode;
  final String? gender;
  final RangeValues? ageRange;
  final String? startingLetter;

  // Optional but very useful additions
  final String? searchQuery;

  FilterState({
    this.province,
    this.district,
    this.municipality,
    this.wardNo,
    this.boothCode,
    this.gender,
    this.ageRange,
    this.startingLetter,
    this.searchQuery,
  });

  FilterState copyWith({
    String? province,
    String? district,
    String? municipality,
    int? wardNo,
    String? boothCode,
    String? gender,
    RangeValues? ageRange,
    String? startingLetter,
    String? searchQuery,
  }) {
    return FilterState(
      province: province ?? this.province,
      district: district ?? this.district,
      municipality: municipality ?? this.municipality,
      wardNo: wardNo ?? this.wardNo,
      boothCode: boothCode ?? this.boothCode,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      startingLetter: startingLetter ?? this.startingLetter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Very useful for UI: check if anything is actually filtered
  bool get isEmpty =>
      province == null &&
      district == null &&
      municipality == null &&
      wardNo == null &&
      boothCode == null &&
      gender == null &&
      ageRange == null &&
      startingLetter == null &&
      (searchQuery?.trim().isEmpty ?? true);

  // Nice formatted summary for showing active filters
  String get summary {
    final parts = <String>[];
    if (province != null) parts.add('प्रदेश: $province');
    if (district != null) parts.add('जिल्ला: $district');
    if (municipality != null) parts.add('नगर/गाउँपालिका: $municipality');
    if (wardNo != null) parts.add('वडा: $wardNo');
    if (boothCode != null) parts.add('बुथ: $boothCode');
    if (gender != null) parts.add('लिङ्ग: $gender');
    if (ageRange != null) {
      parts.add('उमेर: ${ageRange!.start.round()}–${ageRange!.end.round()}');
    }
    if (startingLetter != null) parts.add('सुरु अक्षर: $startingLetter');
    if (searchQuery?.isNotEmpty == true) parts.add('खोजी: "$searchQuery"');

    return parts.isEmpty ? 'सबै' : parts.join(' • ');
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(FilterState());

  void setProvince(String? value) {
    state = state.copyWith(
      province: value,
      district: null,
      municipality: null,
      wardNo: null,
      boothCode: null,
      // Note: searchQuery & startingLetter usually stay across location changes
    );
  }

  void setDistrict(String? value) {
    state = state.copyWith(
      district: value,
      municipality: null,
      wardNo: null,
      boothCode: null,
    );
  }

  void setMunicipality(String? value) {
    state = state.copyWith(municipality: value, wardNo: null, boothCode: null);
  }

  void setWardNo(int? value) {
    state = state.copyWith(wardNo: value, boothCode: null);
  }

  void setBoothCode(String? value) {
    state = state.copyWith(boothCode: value);
  }

  void setGender(String? value) {
    state = state.copyWith(gender: value);
  }

  void setAgeRange(RangeValues? value) {
    state = state.copyWith(ageRange: value);
  }

  void setStartingLetter(String? value) {
    state = state.copyWith(startingLetter: value);
  }

  void setSearchQuery(String? value) {
    state = state.copyWith(searchQuery: value?.trim());
  }

  void clearFilters() {
    state = FilterState();
  }

  // Optional: reset only location-related filters (keep name/gender/age)
  void clearLocation() {
    state = state.copyWith(
      province: null,
      district: null,
      municipality: null,
      wardNo: null,
      boothCode: null,
    );
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>(
  (ref) => FilterNotifier(),
);
