class DiaryEntry {
  final String id;
  final DateTime dateTime;
  // All symptom scores are 0–10
  final int fatigue;
  final int pain;
  final int mood;
  final double sleepHours;
  final String note;
  final bool flareFlag;

  const DiaryEntry({
    required this.id,
    required this.dateTime,
    required this.fatigue,
    required this.pain,
    required this.mood,
    required this.sleepHours,
    this.note = '',
    this.flareFlag = false,
  });

  /// Composite wellness index 0–100. Higher = better day.
  /// Formula: emphasises mood & pain, weighted equally with fatigue.
  int get compositeIndex {
    // Invert fatigue and pain (lower is better), keep mood as-is
    final fatigueScore = (10 - fatigue) * 10;
    final painScore = (10 - pain) * 10;
    final moodScore = mood * 10;
    // Sleep bonus: 7–9h is optimal
    final sleepScore = (sleepHours >= 7 && sleepHours <= 9) ? 100 : (sleepHours * 10).clamp(0, 100).toInt();
    return ((fatigueScore + painScore + moodScore + sleepScore) / 4).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'fatigue': fatigue,
        'pain': pain,
        'mood': mood,
        'sleepHours': sleepHours,
        'note': note,
        'flareFlag': flareFlag,
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        fatigue: json['fatigue'] as int,
        pain: json['pain'] as int,
        mood: json['mood'] as int,
        sleepHours: (json['sleepHours'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        flareFlag: json['flareFlag'] as bool? ?? false,
      );

  DiaryEntry copyWith({
    int? fatigue,
    int? pain,
    int? mood,
    double? sleepHours,
    String? note,
    bool? flareFlag,
  }) =>
      DiaryEntry(
        id: id,
        dateTime: dateTime,
        fatigue: fatigue ?? this.fatigue,
        pain: pain ?? this.pain,
        mood: mood ?? this.mood,
        sleepHours: sleepHours ?? this.sleepHours,
        note: note ?? this.note,
        flareFlag: flareFlag ?? this.flareFlag,
      );
}
