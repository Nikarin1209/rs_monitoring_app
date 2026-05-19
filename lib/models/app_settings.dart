class AppSettings {
  static const List<int> supportedSymptomScaleMax = [5, 10, 100];
  static const Map<String, String> supportedSymptomScaleUnits = {
    'баллов': 'Баллы',
    '%': 'Проценты',
  };
  static const Map<String, String> supportedSleepUnits = {
    'ч': 'Часы',
    'мин': 'Минуты',
  };
  static const Map<String, String> supportedTappingUnits = {
    'уд/с': 'Удары в секунду',
    'наж/с': 'Нажатия в секунду',
  };

  final bool diaryReminderEnabled;
  final bool tappingReminderEnabled;
  final bool reactionReminderEnabled;
  // Times stored as 'HH:MM' strings, e.g. '09:00'
  final String diaryReminderTime;
  final String tappingReminderTime;
  final String reactionReminderTime;
  final bool notificationsEnabled;
  final int symptomScaleMax;
  final String symptomScaleUnit;
  final String sleepUnit;
  final String tappingUnit;

  const AppSettings({
    this.diaryReminderEnabled = true,
    this.tappingReminderEnabled = true,
    this.reactionReminderEnabled = true,
    this.diaryReminderTime = '20:00',
    this.tappingReminderTime = '10:00',
    this.reactionReminderTime = '11:00',
    this.notificationsEnabled = true,
    this.symptomScaleMax = 10,
    this.symptomScaleUnit = 'баллов',
    this.sleepUnit = 'ч',
    this.tappingUnit = 'уд/с',
  });

  static int _parseScaleMax(dynamic value) {
    final parsed = value is int ? value : int.tryParse('$value') ?? 10;
    return supportedSymptomScaleMax.contains(parsed) ? parsed : 10;
  }

  static String _parseUnit(dynamic value, String fallback) {
    final parsed = value as String?;
    if (parsed == null || parsed.trim().isEmpty) return fallback;
    return parsed.trim();
  }

  double symptomValue(num rawValue) => rawValue * symptomScaleMax / 10;

  String formatSymptomValue(num rawValue) {
    final value = symptomValue(rawValue);
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String formatSleepValue(num hours) {
    if (sleepUnit == 'мин') return (hours * 60).round().toString();
    return hours.toStringAsFixed(1);
  }

  String get symptomScaleLabel => '0–$symptomScaleMax';
  String get symptomScaleSuffix => '/$symptomScaleMax';
  String get scalesSummary =>
      '$symptomScaleLabel · $symptomScaleUnit · $sleepUnit';

  Map<String, dynamic> toJson() => {
    'diaryReminderEnabled': diaryReminderEnabled,
    'tappingReminderEnabled': tappingReminderEnabled,
    'reactionReminderEnabled': reactionReminderEnabled,
    'diaryReminderTime': diaryReminderTime,
    'tappingReminderTime': tappingReminderTime,
    'reactionReminderTime': reactionReminderTime,
    'notificationsEnabled': notificationsEnabled,
    'symptomScaleMax': symptomScaleMax,
    'symptomScaleUnit': symptomScaleUnit,
    'sleepUnit': sleepUnit,
    'tappingUnit': tappingUnit,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    diaryReminderEnabled: json['diaryReminderEnabled'] as bool? ?? true,
    tappingReminderEnabled: json['tappingReminderEnabled'] as bool? ?? true,
    reactionReminderEnabled: json['reactionReminderEnabled'] as bool? ?? true,
    diaryReminderTime: json['diaryReminderTime'] as String? ?? '20:00',
    tappingReminderTime: json['tappingReminderTime'] as String? ?? '10:00',
    reactionReminderTime: json['reactionReminderTime'] as String? ?? '11:00',
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    symptomScaleMax: _parseScaleMax(json['symptomScaleMax']),
    symptomScaleUnit: _parseUnit(json['symptomScaleUnit'], 'баллов'),
    sleepUnit: _parseUnit(json['sleepUnit'], 'ч'),
    tappingUnit: _parseUnit(json['tappingUnit'], 'уд/с'),
  );

  AppSettings copyWith({
    bool? diaryReminderEnabled,
    bool? tappingReminderEnabled,
    bool? reactionReminderEnabled,
    String? diaryReminderTime,
    String? tappingReminderTime,
    String? reactionReminderTime,
    bool? notificationsEnabled,
    int? symptomScaleMax,
    String? symptomScaleUnit,
    String? sleepUnit,
    String? tappingUnit,
  }) => AppSettings(
    diaryReminderEnabled: diaryReminderEnabled ?? this.diaryReminderEnabled,
    tappingReminderEnabled:
        tappingReminderEnabled ?? this.tappingReminderEnabled,
    reactionReminderEnabled:
        reactionReminderEnabled ?? this.reactionReminderEnabled,
    diaryReminderTime: diaryReminderTime ?? this.diaryReminderTime,
    tappingReminderTime: tappingReminderTime ?? this.tappingReminderTime,
    reactionReminderTime: reactionReminderTime ?? this.reactionReminderTime,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    symptomScaleMax: symptomScaleMax ?? this.symptomScaleMax,
    symptomScaleUnit: symptomScaleUnit ?? this.symptomScaleUnit,
    sleepUnit: sleepUnit ?? this.sleepUnit,
    tappingUnit: tappingUnit ?? this.tappingUnit,
  );
}
