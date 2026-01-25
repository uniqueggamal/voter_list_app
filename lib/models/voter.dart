class Voter {
  final int id;
  final String voterId;
  final String nameEnglish;
  final String nameNepali;
  final String? nameEn;
  final String? parentname;
  final String? spouseNameNp;
  final String gender;
  final DateTime? dob;
  final int? age;
  final String? citizenshipNo;
  final String? address;
  final int provinceId;
  final String province;
  final int districtId;
  final String district;
  final int municipalityId;
  final String municipality;
  final String municipalityCode;
  final int wardNo;
  final String boothCode;
  final String boothName;
  final String? voterNo; // Optional, as some systems might not have it
  final String? mainCategory;
  final String? subCategory;
  final String? phone;
  final String? description;

  const Voter({
    required this.id,
    required this.voterId,
    required this.nameEnglish,
    required this.nameNepali,
    this.nameEn,
    this.parentname,
    this.spouseNameNp,
    required this.gender,
    this.dob,
    this.age,
    this.citizenshipNo,
    this.address,
    required this.provinceId,
    required this.province,
    required this.districtId,
    required this.district,
    required this.municipalityId,
    required this.municipality,
    required this.municipalityCode,
    required this.wardNo,
    required this.boothCode,
    required this.boothName,
    this.voterNo,
    this.mainCategory,
    this.subCategory,
    this.phone,
    this.description,
  });

  factory Voter.fromMap(Map<String, dynamic> map) {
    return Voter(
      id: map['id'] as int? ?? 0,
      voterId: map['voterId'] as String? ?? map['voter_no'] as String? ?? '',
      nameEnglish:
          map['name_english'] as String? ?? map['nameEnglish'] as String? ?? '',
      nameNepali: map['name'] as String? ?? map['name_np'] as String? ?? '',
      nameEn:
          map['voter_name_en'] as String? ??
          map['name_en'] as String? ??
          map['name_english'] as String?,
      parentname: map['parent_name_np'] as String?,
      spouseNameNp: map['spouse_name_np'] as String?,
      gender: map['gender'] as String? ?? '',
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'] as String) : null,
      age: map['age'] != null
          ? (map['age'] is int
                ? map['age'] as int
                : int.tryParse(map['age'].toString()))
          : null,
      citizenshipNo:
          map['citizenshipNo'] as String? ?? map['citizenship_no'] as String?,
      address: map['address'] as String?,
      provinceId: map['provinceId'] as int? ?? 0,
      province:
          map['province'] as String? ?? map['province_name'] as String? ?? '',
      districtId: map['districtId'] as int? ?? 0,
      district:
          map['district'] as String? ?? map['district_name'] as String? ?? '',
      municipalityId: map['municipalityId'] as int? ?? 0,
      municipality:
          map['municipality'] as String? ??
          map['municipality_name'] as String? ??
          '',
      municipalityCode:
          map['municipalityCode'] as String? ??
          map['municipality_code'] as String? ??
          '',
      wardNo:
          map['wardNo'] as int? ??
          (map['ward_no'] != null
              ? (map['ward_no'] is int
                    ? map['ward_no'] as int
                    : int.tryParse(map['ward_no'].toString()) ?? 0)
              : 0),
      boothCode:
          map['boothCode'] as String? ?? map['booth_code'] as String? ?? '',
      boothName:
          map['boothName'] as String? ?? map['booth_name'] as String? ?? '',
      voterNo: map['voterNo'] as String? ?? map['voter_no'] as String?,
      mainCategory: map['main_category'] as String?,
      subCategory: map['sub_category'] as String?,
      phone: map['voter_phone'] as String? ?? map['phone'] as String?,
      description:
          map['voter_description'] as String? ?? map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voter_id': voterId,
      'name_english': nameEnglish,
      'name_nepali': nameNepali,
      'parent_name_np': parentname,
      'spouse_name_np': spouseNameNp,
      'gender': gender,
      'age': age,
      'province_id': provinceId,
      'province': province,
      'district_id': districtId,
      'district': district,
      'municipality_id': municipalityId,
      'municipality': municipality,
      'municipality_code': municipalityCode,
      'ward_no': wardNo,
      'booth_code': boothCode,
      'booth_name': boothName,
      'voter_no': voterNo,
      'main_category': mainCategory,
      'sub_category': subCategory,
    };
  }

  Voter copyWith({
    int? id,
    String? voterId,
    String? nameEnglish,
    String? nameNepali,
    String? parentname,
    String? spouseNameNp,
    String? gender,
    int? age,
    int? provinceId,
    String? province,
    int? districtId,
    String? district,
    int? municipalityId,
    String? municipality,
    String? municipalityCode,
    int? wardNo,
    String? boothCode,
    String? boothName,
    String? voterNo,
    String? mainCategory,
    String? subCategory,
    String? phone,
    String? description,
  }) {
    return Voter(
      id: id ?? this.id,
      voterId: voterId ?? this.voterId,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameNepali: nameNepali ?? this.nameNepali,
      parentname: parentname ?? this.parentname,
      spouseNameNp: spouseNameNp ?? this.spouseNameNp,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      citizenshipNo: citizenshipNo ?? this.citizenshipNo,
      address: address ?? this.address,
      provinceId: provinceId ?? this.provinceId,
      province: province ?? this.province,
      districtId: districtId ?? this.districtId,
      district: district ?? this.district,
      municipalityId: municipalityId ?? this.municipalityId,
      municipality: municipality ?? this.municipality,
      municipalityCode: municipalityCode ?? this.municipalityCode,
      wardNo: wardNo ?? this.wardNo,
      boothCode: boothCode ?? this.boothCode,
      boothName: boothName ?? this.boothName,
      voterNo: voterNo ?? this.voterNo,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      phone: phone ?? this.phone,
      description: description ?? this.description,
    );
  }

  /// Merges additional data from the editable database with the main voter data
  Voter mergeAdditionalData(Map<String, dynamic>? additionalData) {
    if (additionalData == null) return this;

    return copyWith(
      nameNepali: additionalData['name'] ?? nameNepali,
      nameEnglish: additionalData['english_name'] ?? nameEnglish,
      age: additionalData['age'] != null
          ? int.tryParse(additionalData['age'].toString())
          : age,
      gender: additionalData['gender'] ?? gender,
      parentname: additionalData['parents_name'] ?? parentname,
      wardNo: additionalData['ward_no'] != null
          ? int.tryParse(additionalData['ward_no'].toString())
          : wardNo,
      boothName: additionalData['booth_name'] ?? boothName,
      municipality: additionalData['municipality'] ?? municipality,
      district: additionalData['district'] ?? district,
      province: additionalData['province'] ?? province,
      mainCategory: additionalData['main_category'] ?? mainCategory,
      subCategory: additionalData['sub_category'] ?? subCategory,
    );
  }

  @override
  String toString() {
    return 'Voter(id: $id, voterId: $voterId, nameNepali: $nameNepali)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Voter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
