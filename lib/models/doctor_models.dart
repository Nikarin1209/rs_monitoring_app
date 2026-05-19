import 'diary_entry.dart';
import 'test_result.dart';
import 'user_profile.dart';

class TreatmentPlan {
  final String id;
  final String doctorId;
  final String patientId;
  final String title;
  final String medication;
  final String dosage;
  final String recommendations;
  final String contactNote;
  final DateTime? nextVisitAt;
  final bool active;
  final DateTime createdAt;

  const TreatmentPlan({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.title,
    this.medication = '',
    this.dosage = '',
    this.recommendations = '',
    this.contactNote = '',
    this.nextVisitAt,
    this.active = true,
    required this.createdAt,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  bool isMine(String userId) => senderId == userId;
}

class AppNotification {
  final String id;
  final String userId;
  final String? actorId;
  final String type;
  final String title;
  final String body;
  final String? treatmentPlanId;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.actorId,
    required this.type,
    required this.title,
    required this.body,
    this.treatmentPlanId,
    required this.createdAt,
    this.readAt,
  });

  bool get unread => readAt == null;
}

class DoctorPatientOverview {
  final UserProfile patient;
  final List<DiaryEntry> diaryEntries;
  final List<TestResult> testResults;
  final TreatmentPlan? treatmentPlan;

  const DoctorPatientOverview({
    required this.patient,
    required this.diaryEntries,
    required this.testResults,
    this.treatmentPlan,
  });

  DiaryEntry? get latestDiaryEntry =>
      diaryEntries.isEmpty ? null : diaryEntries.first;

  TestResult? get latestTappingResult {
    for (final result in testResults) {
      if (result.type == TestType.tapping) return result;
    }
    return null;
  }

  TestResult? get latestReactionResult {
    for (final result in testResults) {
      if (result.type == TestType.reaction) return result;
    }
    return null;
  }

  double? averageFatigue(int days) => _average(
    diaryEntries
        .where((entry) => _isWithinDays(entry.dateTime, days))
        .map((entry) => entry.fatigue.toDouble())
        .toList(),
  );

  double? averagePain(int days) => _average(
    diaryEntries
        .where((entry) => _isWithinDays(entry.dateTime, days))
        .map((entry) => entry.pain.toDouble())
        .toList(),
  );

  double? averageMood(int days) => _average(
    diaryEntries
        .where((entry) => _isWithinDays(entry.dateTime, days))
        .map((entry) => entry.mood.toDouble())
        .toList(),
  );

  double? averageMsSymptomBurden(int days) => _average(
    diaryEntries
        .where((entry) => _isWithinDays(entry.dateTime, days))
        .map(
          (entry) =>
              (entry.numbness +
                  entry.coordination +
                  entry.vision +
                  entry.weakness) /
              4,
        )
        .toList(),
  );

  double? averageStress(int days) => _average(
    diaryEntries
        .where((entry) => _isWithinDays(entry.dateTime, days))
        .map((entry) => entry.stress.toDouble())
        .toList(),
  );

  int get warningCount {
    var count = 0;
    final recent = diaryEntries.take(3).toList();
    if (recent.length >= 3 && recent.every((entry) => entry.fatigue >= 7)) {
      count++;
    }
    final fatigue = averageFatigue(7);
    if (fatigue != null && fatigue >= 7) count++;
    final pain = averagePain(7);
    if (pain != null && pain >= 6) count++;
    final msBurden = averageMsSymptomBurden(7);
    if (msBurden != null && msBurden >= 6) count++;
    final stress = averageStress(7);
    if (stress != null && stress >= 7) count++;
    final latestReaction = latestReactionResult;
    if (latestReaction != null && latestReaction.value >= 650) count++;
    return count;
  }

  static bool _isWithinDays(DateTime dateTime, int days) {
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final start = DateTime(from.year, from.month, from.day);
    return !dateTime.isBefore(start);
  }

  static double? _average(List<double> values) {
    if (values.isEmpty) return null;
    return values.fold<double>(0, (sum, value) => sum + value) / values.length;
  }
}
