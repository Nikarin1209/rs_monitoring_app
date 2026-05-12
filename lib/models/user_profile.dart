const _unset = Object();

class UserRole {
  static const patient = 'patient';
  static const doctor = 'doctor';
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime observationStartDate;
  final DateTime? birthDate;
  final String sex;
  final String phone;
  final String msType;
  final DateTime? diagnosisDate;
  final String currentTherapy;
  final String? doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String clinicName;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int baselineFatigue;
  final int baselinePain;
  final double baselineSleep;
  final bool pinEnabled;
  final bool faceIdEnabled;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.patient,
    required this.observationStartDate,
    this.birthDate,
    this.sex = '',
    this.phone = '',
    this.msType = '',
    this.diagnosisDate,
    this.currentTherapy = '',
    this.doctorId,
    this.doctorName = '',
    this.doctorSpecialty = '',
    this.clinicName = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.baselineFatigue = 5,
    this.baselinePain = 3,
    this.baselineSleep = 7.0,
    this.pinEnabled = false,
    this.faceIdEnabled = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'observationStartDate': observationStartDate.toIso8601String(),
    'birthDate': birthDate?.toIso8601String(),
    'sex': sex,
    'phone': phone,
    'msType': msType,
    'diagnosisDate': diagnosisDate?.toIso8601String(),
    'currentTherapy': currentTherapy,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'doctorSpecialty': doctorSpecialty,
    'clinicName': clinicName,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'baselineFatigue': baselineFatigue,
    'baselinePain': baselinePain,
    'baselineSleep': baselineSleep,
    'pinEnabled': pinEnabled,
    'faceIdEnabled': faceIdEnabled,
  };

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    final text = value as String;
    if (text.isEmpty) return null;
    return DateTime.parse(text);
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? UserRole.patient,
    observationStartDate: DateTime.parse(
      json['observationStartDate'] as String,
    ),
    birthDate: _parseOptionalDate(json['birthDate']),
    sex: json['sex'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    msType: json['msType'] as String? ?? '',
    diagnosisDate: _parseOptionalDate(json['diagnosisDate']),
    currentTherapy: json['currentTherapy'] as String? ?? '',
    doctorId: json['doctorId'] as String?,
    doctorName: json['doctorName'] as String? ?? '',
    doctorSpecialty: json['doctorSpecialty'] as String? ?? '',
    clinicName: json['clinicName'] as String? ?? '',
    emergencyContactName: json['emergencyContactName'] as String? ?? '',
    emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
    baselineFatigue: json['baselineFatigue'] as int? ?? 5,
    baselinePain: json['baselinePain'] as int? ?? 3,
    baselineSleep: (json['baselineSleep'] as num?)?.toDouble() ?? 7.0,
    pinEnabled: json['pinEnabled'] as bool? ?? false,
    faceIdEnabled: json['faceIdEnabled'] as bool? ?? false,
  );

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;

  UserProfile copyWith({
    String? name,
    String? email,
    String? role,
    DateTime? observationStartDate,
    Object? birthDate = _unset,
    String? sex,
    String? phone,
    String? msType,
    Object? diagnosisDate = _unset,
    String? currentTherapy,
    Object? doctorId = _unset,
    String? doctorName,
    String? doctorSpecialty,
    String? clinicName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    int? baselineFatigue,
    int? baselinePain,
    double? baselineSleep,
    bool? pinEnabled,
    bool? faceIdEnabled,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    observationStartDate: observationStartDate ?? this.observationStartDate,
    birthDate: birthDate == _unset ? this.birthDate : birthDate as DateTime?,
    sex: sex ?? this.sex,
    phone: phone ?? this.phone,
    msType: msType ?? this.msType,
    diagnosisDate: diagnosisDate == _unset
        ? this.diagnosisDate
        : diagnosisDate as DateTime?,
    currentTherapy: currentTherapy ?? this.currentTherapy,
    doctorId: doctorId == _unset ? this.doctorId : doctorId as String?,
    doctorName: doctorName ?? this.doctorName,
    doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
    clinicName: clinicName ?? this.clinicName,
    emergencyContactName: emergencyContactName ?? this.emergencyContactName,
    emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    baselineFatigue: baselineFatigue ?? this.baselineFatigue,
    baselinePain: baselinePain ?? this.baselinePain,
    baselineSleep: baselineSleep ?? this.baselineSleep,
    pinEnabled: pinEnabled ?? this.pinEnabled,
    faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
  );
}

class DoctorListItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialty;
  final String clinicName;

  const DoctorListItem({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.specialty = '',
    this.clinicName = '',
  });

  String get label {
    final details = [
      if (specialty.isNotEmpty) specialty,
      if (clinicName.isNotEmpty) clinicName,
    ].join(' · ');
    return details.isEmpty ? name : '$name — $details';
  }
}
