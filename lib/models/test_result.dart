/// Supported test types.
class TestType {
  static const tapping = 'tapping';
  static const reaction = 'reaction';
}

/// Supported hand values for tapping tests.
class TestHand {
  static const left = 'left';
  static const right = 'right';
}

class TestResult {
  final String id;
  // 'tapping' or 'reaction' — use TestType constants
  final String type;
  final DateTime dateTime;
  // Tapping: taps per second. Reaction: average reaction time in ms.
  final double value;
  final int durationSeconds;
  // 'left', 'right', or null (reaction test has no hand)
  final String? hand;
  // Extra data serialised as JSON string (e.g., raw tap timestamps)
  final String? metadataJson;

  const TestResult({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.value,
    required this.durationSeconds,
    this.hand,
    this.metadataJson,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'dateTime': dateTime.toIso8601String(),
        'value': value,
        'durationSeconds': durationSeconds,
        'hand': hand,
        'metadataJson': metadataJson,
      };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        id: json['id'] as String,
        type: json['type'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        value: (json['value'] as num).toDouble(),
        durationSeconds: json['durationSeconds'] as int,
        hand: json['hand'] as String?,
        metadataJson: json['metadataJson'] as String?,
      );
}
