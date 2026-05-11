class AppSettings {
  final bool diaryReminderEnabled;
  final bool tappingReminderEnabled;
  final bool reactionReminderEnabled;
  // Times stored as 'HH:MM' strings, e.g. '09:00'
  final String diaryReminderTime;
  final String tappingReminderTime;
  final String reactionReminderTime;
  final bool notificationsEnabled;

  const AppSettings({
    this.diaryReminderEnabled = true,
    this.tappingReminderEnabled = true,
    this.reactionReminderEnabled = true,
    this.diaryReminderTime = '20:00',
    this.tappingReminderTime = '10:00',
    this.reactionReminderTime = '11:00',
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'diaryReminderEnabled': diaryReminderEnabled,
        'tappingReminderEnabled': tappingReminderEnabled,
        'reactionReminderEnabled': reactionReminderEnabled,
        'diaryReminderTime': diaryReminderTime,
        'tappingReminderTime': tappingReminderTime,
        'reactionReminderTime': reactionReminderTime,
        'notificationsEnabled': notificationsEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        diaryReminderEnabled: json['diaryReminderEnabled'] as bool? ?? true,
        tappingReminderEnabled: json['tappingReminderEnabled'] as bool? ?? true,
        reactionReminderEnabled: json['reactionReminderEnabled'] as bool? ?? true,
        diaryReminderTime: json['diaryReminderTime'] as String? ?? '20:00',
        tappingReminderTime: json['tappingReminderTime'] as String? ?? '10:00',
        reactionReminderTime: json['reactionReminderTime'] as String? ?? '11:00',
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      );

  AppSettings copyWith({
    bool? diaryReminderEnabled,
    bool? tappingReminderEnabled,
    bool? reactionReminderEnabled,
    String? diaryReminderTime,
    String? tappingReminderTime,
    String? reactionReminderTime,
    bool? notificationsEnabled,
  }) =>
      AppSettings(
        diaryReminderEnabled: diaryReminderEnabled ?? this.diaryReminderEnabled,
        tappingReminderEnabled: tappingReminderEnabled ?? this.tappingReminderEnabled,
        reactionReminderEnabled: reactionReminderEnabled ?? this.reactionReminderEnabled,
        diaryReminderTime: diaryReminderTime ?? this.diaryReminderTime,
        tappingReminderTime: tappingReminderTime ?? this.tappingReminderTime,
        reactionReminderTime: reactionReminderTime ?? this.reactionReminderTime,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}
