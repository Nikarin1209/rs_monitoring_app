import 'dart:math' as math;
import '../models/diary_entry.dart';
import '../models/test_result.dart';

class AnalysisSignal {
  final String title;
  final String description;
  // 'high', 'warn', 'info'
  final String severity;
  final DateTime dateTime;

  const AnalysisSignal({
    required this.title,
    required this.description,
    required this.severity,
    required this.dateTime,
  });
}

class AnalyticsService {
  // ── Descriptive statistics ──────────────────────────────────────────────

  static double? mean(List<double> values) {
    if (values.isEmpty) return null;
    return values.fold(0.0, (s, v) => s + v) / values.length;
  }

  static double? median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static double? minValue(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce(math.min);
  }

  static double? maxValue(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce(math.max);
  }

  /// Sample standard deviation (n-1 denominator).
  static double? standardDeviation(List<double> values) {
    if (values.length < 2) return null;
    final avg = mean(values)!;
    final variance = values.fold(0.0, (s, v) => s + (v - avg) * (v - avg)) /
        (values.length - 1);
    return math.sqrt(variance);
  }

  // ── Time series helpers ─────────────────────────────────────────────────

  /// Moving average; output length equals input length.
  static List<double> movingAverage(List<double> values, int window) {
    if (values.isEmpty || window <= 0) return [];
    return List.generate(values.length, (i) {
      final start = math.max(0, i - window + 1);
      final slice = values.sublist(start, i + 1);
      return slice.fold(0.0, (s, v) => s + v) / slice.length;
    });
  }

  static double? percentChange(double? current, double? previous) {
    if (current == null || previous == null || previous == 0) return null;
    return (current - previous) / previous * 100;
  }

  static List<DiaryEntry> entriesForLastDays(
      List<DiaryEntry> entries, int days) {
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final start = DateTime(from.year, from.month, from.day);
    return entries.where((e) => !e.dateTime.isBefore(start)).toList();
  }

  static List<DiaryEntry> entriesForPreviousDays(
      List<DiaryEntry> entries, int days) {
    final now = DateTime.now();
    final windowEnd = now.subtract(Duration(days: days));
    final windowStart = now.subtract(Duration(days: days * 2));
    final start = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final end = DateTime(windowEnd.year, windowEnd.month, windowEnd.day, 23, 59, 59);
    return entries
        .where((e) => !e.dateTime.isBefore(start) && !e.dateTime.isAfter(end))
        .toList();
  }

  static List<TestResult> testResultsForLastDays(
      List<TestResult> results, int days, String type) {
    final from = DateTime.now().subtract(Duration(days: days));
    return results
        .where((r) => r.type == type && !r.dateTime.isBefore(from))
        .toList();
  }

  static List<TestResult> testResultsForPreviousDays(
      List<TestResult> results, int days, String type) {
    final now = DateTime.now();
    final to = now.subtract(Duration(days: days));
    final from = now.subtract(Duration(days: days * 2));
    return results
        .where((r) =>
            r.type == type &&
            !r.dateTime.isBefore(from) &&
            !r.dateTime.isAfter(to))
        .toList();
  }

  // ── Metric extraction ───────────────────────────────────────────────────

  static List<double> fatigueValues(List<DiaryEntry> entries) =>
      entries.map((e) => e.fatigue.toDouble()).toList();

  static List<double> painValues(List<DiaryEntry> entries) =>
      entries.map((e) => e.pain.toDouble()).toList();

  static List<double> moodValues(List<DiaryEntry> entries) =>
      entries.map((e) => e.mood.toDouble()).toList();

  static List<double> sleepValues(List<DiaryEntry> entries) =>
      entries.map((e) => e.sleepHours).toList();

  // ── Composite condition index ───────────────────────────────────────────
  // This index is intended only for self-monitoring and is not a medical diagnosis.
  //
  // Formula:
  //   fatigueNorm  = fatigue / 10
  //   painNorm     = pain / 10
  //   moodBadNorm  = 1 − mood / 10
  //   scoreBad     = 0.4·fatigueNorm + 0.3·painNorm + 0.3·moodBadNorm
  //   index        = round((1 − scoreBad) × 100)

  static int? calculateCompositeIndexFromEntry(DiaryEntry entry) {
    return calculateCompositeIndexFromAverages(
      fatigue: entry.fatigue.toDouble(),
      pain: entry.pain.toDouble(),
      mood: entry.mood.toDouble(),
    );
  }

  static int? calculateCompositeIndexFromAverages({
    required double fatigue,
    required double pain,
    required double mood,
  }) {
    final fatigueNorm = fatigue / 10;
    final painNorm = pain / 10;
    final moodBadNorm = 1 - mood / 10;
    final scoreBad =
        0.4 * fatigueNorm + 0.3 * painNorm + 0.3 * moodBadNorm;
    return ((1 - scoreBad) * 100).round();
  }

  static double? calculateAverageCompositeIndex(List<DiaryEntry> entries) {
    if (entries.isEmpty) return null;
    final indices = entries
        .map(calculateCompositeIndexFromEntry)
        .whereType<int>()
        .toList();
    if (indices.isEmpty) return null;
    return indices.fold(0.0, (s, v) => s + v) / indices.length;
  }

  // ── Signals ─────────────────────────────────────────────────────────────

  static List<AnalysisSignal> generateSignals(
    List<DiaryEntry> entries,
    List<TestResult> testResults,
  ) {
    final signals = <AnalysisSignal>[];
    final now = DateTime.now();

    final sorted = List<DiaryEntry>.from(entries)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // A. Fatigue streak: fatigue >= 7 for 3 latest entries
    if (sorted.length >= 3 && sorted.take(3).every((e) => e.fatigue >= 7)) {
      signals.add(AnalysisSignal(
        title: 'Усталость растёт',
        description: 'Усталость ≥ 7 в течение 3 записей подряд. '
            'Следите за состоянием и при необходимости обсудите изменения с врачом.',
        severity: 'high',
        dateTime: now,
      ));
    }

    // B. Fatigue trend: avg last 7 days increased >= 20% vs previous 7 days
    final last7Fatigue =
        mean(fatigueValues(entriesForLastDays(entries, 7)));
    final prev7Fatigue =
        mean(fatigueValues(entriesForPreviousDays(entries, 7)));
    final fatigueChange = percentChange(last7Fatigue, prev7Fatigue);
    if (fatigueChange != null && fatigueChange >= 20) {
      signals.add(AnalysisSignal(
        title: 'Усталость увеличивается',
        description:
            'Средняя усталость за 7 дней выросла на ${fatigueChange.round()}% '
            'по сравнению с предыдущей неделей. Возможный сигнал ухудшения. '
            'Следите за состоянием и при необходимости обратитесь к врачу.',
        severity: 'warn',
        dateTime: now,
      ));
    }

    // C. Pain trend: avg last 7 days increased >= 20% vs previous 7 days
    final last7Pain = mean(painValues(entriesForLastDays(entries, 7)));
    final prev7Pain = mean(painValues(entriesForPreviousDays(entries, 7)));
    final painChange = percentChange(last7Pain, prev7Pain);
    if (painChange != null && painChange >= 20) {
      signals.add(AnalysisSignal(
        title: 'Боль увеличивается',
        description:
            'Средняя боль за 7 дней выросла на ${painChange.round()}% '
            'по сравнению с предыдущей неделей. Возможный сигнал ухудшения. '
            'Следите за состоянием и при необходимости обратитесь к врачу.',
        severity: 'warn',
        dateTime: now,
      ));
    }

    // D. Reaction time trend: median/avg last 7 days increased >= 15% vs previous 7 days
    final last7React =
        testResultsForLastDays(testResults, 7, TestType.reaction);
    final prev7React =
        testResultsForPreviousDays(testResults, 7, TestType.reaction);
    if (last7React.isNotEmpty && prev7React.isNotEmpty) {
      final last7ReactAvg =
          last7React.fold(0.0, (s, r) => s + r.value) / last7React.length;
      final prev7ReactAvg =
          prev7React.fold(0.0, (s, r) => s + r.value) / prev7React.length;
      final reactChange = percentChange(last7ReactAvg, prev7ReactAvg);
      if (reactChange != null && reactChange >= 15) {
        signals.add(AnalysisSignal(
          title: 'Время реакции замедляется',
          description:
              'Медианное время реакции выросло на ${reactChange.round()}% за 7 дней. '
              'Возможный сигнал ухудшения. '
              'Следите за состоянием и при необходимости обратитесь к врачу.',
          severity: 'warn',
          dateTime: now,
        ));
      }
    }

    // E. Sleep + fatigue: sleep avg < 6h AND fatigue avg >= 7 during last 7 days
    final last7Entries = entriesForLastDays(entries, 7);
    final last7Sleep = mean(sleepValues(last7Entries));
    final last7FatigueAvg = mean(fatigueValues(last7Entries));
    if (last7Sleep != null &&
        last7FatigueAvg != null &&
        last7Sleep < 6 &&
        last7FatigueAvg >= 7) {
      signals.add(AnalysisSignal(
        title: 'Недосыпание и усталость',
        description:
            'Среднее время сна менее 6 ч и высокая усталость за последние 7 дней. '
            'Возможный сигнал ухудшения. '
            'Следите за состоянием и при необходимости обратитесь к врачу.',
        severity: 'warn',
        dateTime: now,
      ));
    }

    return signals;
  }

  // ── Correlations ────────────────────────────────────────────────────────

  /// Pearson correlation coefficient. Returns null if fewer than 5 pairs.
  static double? pearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 5) return null;
    final n = x.length;
    final mx = mean(x)!;
    final my = mean(y)!;
    double num = 0, dx2 = 0, dy2 = 0;
    for (int i = 0; i < n; i++) {
      num += (x[i] - mx) * (y[i] - my);
      dx2 += (x[i] - mx) * (x[i] - mx);
      dy2 += (y[i] - my) * (y[i] - my);
    }
    final denom = math.sqrt(dx2 * dy2);
    if (denom == 0) return null;
    return (num / denom).clamp(-1.0, 1.0);
  }

  /// Spearman rank correlation. Returns null if fewer than 5 pairs.
  static double? spearmanCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 5) return null;
    return pearsonCorrelation(_ranks(x), _ranks(y));
  }

  /// Computes average ranks (handles ties).
  static List<double> _ranks(List<double> values) {
    final indexed =
        List.generate(values.length, (i) => MapEntry(i, values[i]));
    indexed.sort((a, b) => a.value.compareTo(b.value));
    final ranks = List<double>.filled(values.length, 0);
    int i = 0;
    while (i < indexed.length) {
      int j = i;
      while (j < indexed.length - 1 &&
          indexed[j + 1].value == indexed[i].value) {
        j++;
      }
      final rank = (i + j + 2) / 2.0; // 1-based average rank
      for (int k = i; k <= j; k++) {
        ranks[indexed[k].key] = rank;
      }
      i = j + 1;
    }
    return ranks;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Human-readable interpretation of correlation strength.
  static String correlationLabel(double r) {
    final abs = r.abs();
    if (abs < 0.3) return 'слабая связь';
    if (abs < 0.5) return 'умеренная связь';
    return 'заметная связь';
  }

  /// Sign description.
  static String correlationSign(double r) {
    if (r > 0.05) return 'прямая';
    if (r < -0.05) return 'обратная';
    return 'нет связи';
  }
}
