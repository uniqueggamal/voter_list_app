class Voter {
  final int id;
  final String voterId;
  final String nameEnglish;
  final String nameNepali;
  final String? fatherName;
  final String? motherName;
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

  const Voter({
    required this.id,
    required this.voterId,
    required this.nameEnglish,
    required this.nameNepali,
    this.fatherName,
    this.motherName,
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
  });

  factory Voter.fromMap(Map<String, dynamic> map) {
    return Voter(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      voterId: map['id'].toString(),
      nameEnglish: '',
      nameNepali: map['name_np'] as String? ?? '',
      fatherName: map['father_name'] as String?,
      motherName: map['mother_name'] as String?,
      gender: map['gender'] as String? ?? '',
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'] as String) : null,
      age: map['age'] != null ? int.tryParse(map['age'].toString()) : null,
      citizenshipNo: map['citizenship_no'] as String?,
      address: map['address'] as String?,
      provinceId: 0,
      province: map['province'] as String? ?? '',
      districtId: 0,
      district: map['district'] as String? ?? '',
      municipalityId: 0,
      municipality: map['municipality'] as String? ?? '',
      municipalityCode: map['municipality_code'] as String? ?? '',
      wardNo: int.tryParse(map['ward_no']?.toString() ?? '') ?? 0,
      boothCode: map['booth_code'] as String? ?? '',
      boothName: map['booth_name'] as String? ?? '',
      voterNo: map['voter_no'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voter_id': voterId,
      'name_english': nameEnglish,
      'name_nepali': nameNepali,
      'father_name': fatherName,
      'mother_name': motherName,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'age': age,
      'citizenship_no': citizenshipNo,
      'address': address,
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
    };
  }

  Voter copyWith({
    int? id,
    String? voterId,
    String? nameEnglish,
    String? nameNepali,
    String? fatherName,
    String? motherName,
    String? gender,
    DateTime? dob,
    int? age,
    String? citizenshipNo,
    String? address,
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
  }) {
    return Voter(
      id: id ?? this.id,
      voterId: voterId ?? this.voterId,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameNepali: nameNepali ?? this.nameNepali,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
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
