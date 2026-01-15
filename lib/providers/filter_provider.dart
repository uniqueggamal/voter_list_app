import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_params.dart';

class FilterState {
  final String? province;
  final String? district;
  final String? municipality;
  final int? wardNo;
  final String? boothCode;
  final String? gender;
  final int? minAge;
  final int? maxAge;
  final String? startingLetter;
  final String?
  mainCategory; // e.g. "Chhetri", "Brahmin", "Tharu", etc. from group_category

  // Optional: keep search query here if you want filters + search combined
  final String? searchQuery;
  final SearchField searchField;
  final SearchMatchMode searchMatchMode;

  const FilterState({
    this.province,
    this.district,
    this.municipality,
    this.wardNo,
    this.boothCode,
    this.gender,
    this.minAge,
    this.maxAge,
    this.startingLetter,
    this.mainCategory,
    this.searchQuery,
    this.searchField = SearchField.name,
    this.searchMatchMode = SearchMatchMode.startsWith,
  });

  FilterState copyWith({
    String? province,
    String? district,
    String? municipality,
    int? wardNo,
    String? boothCode,
    String? gender,
    int? minAge,
    int? maxAge,
    String? startingLetter,
    String? mainCategory,
    String? searchQuery,
    SearchField? searchField,
    SearchMatchMode? searchMatchMode,
  }) {
    return FilterState(
      province: province ?? this.province,
      district: district ?? this.district,
      municipality: municipality ?? this.municipality,
      wardNo: wardNo ?? this.wardNo,
      boothCode: boothCode ?? this.boothCode,
      gender: gender ?? this.gender,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      startingLetter: startingLetter ?? this.startingLetter,
      mainCategory: mainCategory ?? this.mainCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      searchField: searchField ?? this.searchField,
      searchMatchMode: searchMatchMode ?? this.searchMatchMode,
    );
  }

  // Check if any filter is active (this replaces the old hasAnyFilter)
  bool get hasAnyFilter {
    return province != null ||
        district != null ||
        municipality != null ||
        wardNo != null ||
        boothCode != null ||
        gender != null ||
        minAge != null ||
        maxAge != null ||
        startingLetter != null ||
        mainCategory != null ||
        (searchQuery?.trim().isNotEmpty ?? false);
  }

  // Alternative name: isDefault / isNotFiltered
  bool get isDefault => !hasAnyFilter;

  // Nice formatted summary for UI chips or display
  String get summary {
    final parts = <String>[];
    if (province != null) parts.add('प्रदेश: $province');
    if (district != null) parts.add('जिल्ला: $district');
    if (municipality != null) parts.add('नगर/गाउँपालिका: $municipality');
    if (wardNo != null) parts.add('वडा: $wardNo');
    if (boothCode != null) parts.add('बुथ: $boothCode');
    if (gender != null) parts.add('लिङ्ग: $gender');
    if (minAge != null || maxAge != null) {
      parts.add('उमेर: ${minAge ?? 18}–${maxAge ?? 100}');
    }
    if (startingLetter != null) parts.add('सुरु: $startingLetter');
    if (mainCategory != null) parts.add('समूह: $mainCategory');
    if (searchQuery?.isNotEmpty == true) parts.add('खोजी: "$searchQuery"');

    return parts.isEmpty ? 'सबै' : parts.join(' • ');
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setProvince(String? value) {
    state = state.copyWith(
      province: value,
      // Reset lower levels when province changes
      district: null,
      municipality: null,
      wardNo: null,
      boothCode: null,
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

  void setAgeRange(int? min, int? max) {
    state = state.copyWith(minAge: min, maxAge: max);
  }

  void setStartingLetter(String? value) {
    state = state.copyWith(startingLetter: value);
  }

  void setMainCategory(String? value) {
    state = state.copyWith(mainCategory: value);
  }

  void setSearchQuery(String? value) {
    state = state.copyWith(searchQuery: value?.trim());
  }

  void clearFilters() {
    state = const FilterState();
  }

  void clearLocationFilters() {
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
