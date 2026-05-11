class UserProfile {
  final String id;
  final String name;
  final String email;
  final DateTime observationStartDate;
  final int baselineFatigue;
  final int baselinePain;
  final double baselineSleep;
  final bool pinEnabled;
  final bool faceIdEnabled;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.observationStartDate,
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
        'observationStartDate': observationStartDate.toIso8601String(),
        'baselineFatigue': baselineFatigue,
        'baselinePain': baselinePain,
        'baselineSleep': baselineSleep,
        'pinEnabled': pinEnabled,
        'faceIdEnabled': faceIdEnabled,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        observationStartDate: DateTime.parse(json['observationStartDate'] as String),
        baselineFatigue: json['baselineFatigue'] as int? ?? 5,
        baselinePain: json['baselinePain'] as int? ?? 3,
        baselineSleep: (json['baselineSleep'] as num?)?.toDouble() ?? 7.0,
        pinEnabled: json['pinEnabled'] as bool? ?? false,
        faceIdEnabled: json['faceIdEnabled'] as bool? ?? false,
      );

  UserProfile copyWith({
    String? name,
    String? email,
    DateTime? observationStartDate,
    int? baselineFatigue,
    int? baselinePain,
    double? baselineSleep,
    bool? pinEnabled,
    bool? faceIdEnabled,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        observationStartDate: observationStartDate ?? this.observationStartDate,
        baselineFatigue: baselineFatigue ?? this.baselineFatigue,
        baselinePain: baselinePain ?? this.baselinePain,
        baselineSleep: baselineSleep ?? this.baselineSleep,
        pinEnabled: pinEnabled ?? this.pinEnabled,
        faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
      );
}
