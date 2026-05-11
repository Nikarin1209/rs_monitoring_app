import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../models/test_result.dart';
import '../models/user_profile.dart';
import 'analytics_service.dart';

class ExportService {
  // ── CSV helpers ─────────────────────────────────────────────────────────

  static String _cell(String value) {
    // RFC 4180: wrap in quotes if the field contains comma, quote, or newline.
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _row(List<String> cells) =>
      cells.map(_cell).join(',');

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _formatDateTime(DateTime dt) => dt.toIso8601String();

  // ── Period filters ──────────────────────────────────────────────────────

  static List<DiaryEntry> filterDiaryByPeriod(
      List<DiaryEntry> all, int? days) {
    if (days == null) return all;
    return AnalyticsService.entriesForLastDays(all, days);
  }

  static List<TestResult> filterTestsByPeriod(
      List<TestResult> all, int? days) {
    if (days == null) return all;
    final from = DateTime.now().subtract(Duration(days: days));
    return all.where((r) => !r.dateTime.isBefore(from)).toList();
  }

  // ── CSV builder ─────────────────────────────────────────────────────────

  static String buildCsvContent({
    required UserProfile? profile,
    required List<DiaryEntry> diaryEntries,
    required List<TestResult> testResults,
    required String periodLabel,
  }) {
    final buf = StringBuffer();
    final now = DateTime.now();

    // ── Report header ──────────────────────────────────────────────────────
    buf.writeln('# NeuroLife — Patient Monitoring Report');
    buf.writeln('# App,NeuroLife');
    buf.writeln('# Report type,Patient monitoring report');
    buf.writeln('# Patient,${profile?.name ?? ''}');
    buf.writeln('# Email,${profile?.email ?? ''}');
    if (profile != null) {
      buf.writeln(
          '# Observation start,${_formatDate(profile.observationStartDate)}');
    }
    buf.writeln('# Export date,${_formatDateTime(now)}');
    buf.writeln('# Period,$periodLabel');
    buf.writeln();

    // ── Diary entries ──────────────────────────────────────────────────────
    buf.writeln('## DIARY ENTRIES');
    buf.writeln(_row(
        ['date', 'fatigue', 'pain', 'mood', 'sleepHours', 'note', 'flareFlag']));
    final sortedDiary = List<DiaryEntry>.from(diaryEntries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    for (final e in sortedDiary) {
      buf.writeln(_row([
        _formatDateTime(e.dateTime),
        e.fatigue.toString(),
        e.pain.toString(),
        e.mood.toString(),
        e.sleepHours.toStringAsFixed(1),
        e.note,
        e.flareFlag.toString(),
      ]));
    }
    buf.writeln();

    // ── Tapping test results ───────────────────────────────────────────────
    final tapping = testResults
        .where((r) => r.type == TestType.tapping)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    buf.writeln('## TAPPING TESTS');
    buf.writeln(_row(
        ['date', 'tapsPerSecond', 'totalTaps', 'durationSeconds', 'hand']));
    for (final r in tapping) {
      // totalTaps = tapsPerSecond × durationSeconds
      final total = (r.value * r.durationSeconds).round();
      buf.writeln(_row([
        _formatDateTime(r.dateTime),
        r.value.toStringAsFixed(2),
        total.toString(),
        r.durationSeconds.toString(),
        r.hand ?? '',
      ]));
    }
    buf.writeln();

    // ── Reaction test results ──────────────────────────────────────────────
    final reaction = testResults
        .where((r) => r.type == TestType.reaction)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    buf.writeln('## REACTION TESTS');
    buf.writeln(_row(
        ['date', 'medianReactionMs', 'durationSeconds', 'metadataJson']));
    for (final r in reaction) {
      buf.writeln(_row([
        _formatDateTime(r.dateTime),
        r.value.toStringAsFixed(1),
        r.durationSeconds.toString(),
        r.metadataJson ?? '',
      ]));
    }
    buf.writeln();

    // ── Analytics summary ──────────────────────────────────────────────────
    buf.writeln('## ANALYTICS SUMMARY');
    buf.writeln(_row(['metric', 'value']));

    final avgFatigue =
        AnalyticsService.mean(AnalyticsService.fatigueValues(diaryEntries));
    final avgPain =
        AnalyticsService.mean(AnalyticsService.painValues(diaryEntries));
    final avgMood =
        AnalyticsService.mean(AnalyticsService.moodValues(diaryEntries));
    final avgSleep =
        AnalyticsService.mean(AnalyticsService.sleepValues(diaryEntries));
    final avgIndex =
        AnalyticsService.calculateAverageCompositeIndex(diaryEntries);
    final signals =
        AnalyticsService.generateSignals(diaryEntries, testResults);

    buf.writeln(_row(['avgFatigue', avgFatigue?.toStringAsFixed(2) ?? '']));
    buf.writeln(_row(['avgPain', avgPain?.toStringAsFixed(2) ?? '']));
    buf.writeln(_row(['avgMood', avgMood?.toStringAsFixed(2) ?? '']));
    buf.writeln(_row(['avgSleep', avgSleep?.toStringAsFixed(2) ?? '']));
    buf.writeln(
        _row(['avgCompositeIndex', avgIndex?.toStringAsFixed(1) ?? '']));
    buf.writeln(_row(['activeSignalsCount', signals.length.toString()]));
    buf.writeln(_row(
        ['activeSignalTitles', signals.map((s) => s.title).join('; ')]));
    buf.writeln();

    // ── Active signals ─────────────────────────────────────────────────────
    buf.writeln('## ACTIVE SIGNALS');
    buf.writeln(_row(['date', 'severity', 'title', 'description']));
    for (final s in signals) {
      buf.writeln(_row([
        _formatDateTime(s.dateTime),
        s.severity,
        s.title,
        s.description,
      ]));
    }

    return buf.toString();
  }

  // ── File export ─────────────────────────────────────────────────────────

  static Future<File> exportCsv({
    required UserProfile? profile,
    required List<DiaryEntry> diaryEntries,
    required List<TestResult> testResults,
    required String periodLabel,
  }) async {
    final content = buildCsvContent(
      profile: profile,
      diaryEntries: diaryEntries,
      testResults: testResults,
      periodLabel: periodLabel,
    );
    final dir = await getTemporaryDirectory();
    final date = _formatDate(DateTime.now());
    final file = File('${dir.path}/NeuroLife_Report_$date.csv');
    await file.writeAsString(content, encoding: utf8);
    return file;
  }

  // TODO: PDF export via the `pdf` and `printing` packages.
  // Would require adding: pdf: ^3.11.0, printing: ^5.13.0
  // and building a PdfDocument with tables for each section.
}
