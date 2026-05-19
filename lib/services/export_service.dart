import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/diary_entry.dart';
import '../models/test_result.dart';
import '../models/user_profile.dart';
import 'analytics_service.dart';

class ExportedReport {
  final String filename;
  final Uint8List bytes;
  final String mimeType;

  const ExportedReport({
    required this.filename,
    required this.bytes,
    required this.mimeType,
  });
}

class ExportService {
  // ── CSV helpers ─────────────────────────────────────────────────────────

  static String _cell(String value) {
    // RFC 4180: wrap in quotes if the field contains comma, quote, or newline.
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _row(List<String> cells) => cells.map(_cell).join(',');

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _formatDateTime(DateTime dt) => dt.toIso8601String();

  static String _formatHumanDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  static String _formatHumanDateTime(DateTime dt) =>
      '${_formatHumanDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _blank(String value) => value.trim().isEmpty ? '-' : value;

  static String _fixed(double? value, int digits) =>
      value == null ? '-' : value.toStringAsFixed(digits);

  static String _reportFilename(String extension) {
    final date = _formatDate(DateTime.now());
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'NeuroLife_Report_${date}_$stamp.$extension';
  }

  // ── Period filters ──────────────────────────────────────────────────────

  static List<DiaryEntry> filterDiaryByPeriod(List<DiaryEntry> all, int? days) {
    if (days == null) return all;
    return AnalyticsService.entriesForLastDays(all, days);
  }

  static List<TestResult> filterTestsByPeriod(List<TestResult> all, int? days) {
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
        '# Observation start,${_formatDate(profile.observationStartDate)}',
      );
    }
    buf.writeln('# Export date,${_formatDateTime(now)}');
    buf.writeln('# Period,$periodLabel');
    buf.writeln();

    // ── Diary entries ──────────────────────────────────────────────────────
    buf.writeln('## DIARY ENTRIES');
    buf.writeln(
      _row([
        'date',
        'fatigue',
        'pain',
        'mood',
        'numbness',
        'coordination',
        'vision',
        'weakness',
        'stress',
        'sleepHours',
        'note',
        'flareFlag',
      ]),
    );
    final sortedDiary = List<DiaryEntry>.from(diaryEntries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    for (final e in sortedDiary) {
      buf.writeln(
        _row([
          _formatDateTime(e.dateTime),
          e.fatigue.toString(),
          e.pain.toString(),
          e.mood.toString(),
          e.numbness.toString(),
          e.coordination.toString(),
          e.vision.toString(),
          e.weakness.toString(),
          e.stress.toString(),
          e.sleepHours.toStringAsFixed(1),
          e.note,
          e.flareFlag.toString(),
        ]),
      );
    }
    buf.writeln();

    // ── Tapping test results ───────────────────────────────────────────────
    final tapping =
        testResults.where((r) => r.type == TestType.tapping).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    buf.writeln('## TAPPING TESTS');
    buf.writeln(
      _row(['date', 'tapsPerSecond', 'totalTaps', 'durationSeconds', 'hand']),
    );
    for (final r in tapping) {
      // totalTaps = tapsPerSecond × durationSeconds
      final total = (r.value * r.durationSeconds).round();
      buf.writeln(
        _row([
          _formatDateTime(r.dateTime),
          r.value.toStringAsFixed(2),
          total.toString(),
          r.durationSeconds.toString(),
          r.hand ?? '',
        ]),
      );
    }
    buf.writeln();

    // ── Reaction test results ──────────────────────────────────────────────
    final reaction =
        testResults.where((r) => r.type == TestType.reaction).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    buf.writeln('## REACTION TESTS');
    buf.writeln(
      _row(['date', 'medianReactionMs', 'durationSeconds', 'metadataJson']),
    );
    for (final r in reaction) {
      buf.writeln(
        _row([
          _formatDateTime(r.dateTime),
          r.value.toStringAsFixed(1),
          r.durationSeconds.toString(),
          r.metadataJson ?? '',
        ]),
      );
    }
    buf.writeln();

    // ── Analytics summary ──────────────────────────────────────────────────
    buf.writeln('## ANALYTICS SUMMARY');
    buf.writeln(_row(['metric', 'value']));

    final avgFatigue = AnalyticsService.mean(
      AnalyticsService.fatigueValues(diaryEntries),
    );
    final avgPain = AnalyticsService.mean(
      AnalyticsService.painValues(diaryEntries),
    );
    final avgMood = AnalyticsService.mean(
      AnalyticsService.moodValues(diaryEntries),
    );
    final avgSleep = AnalyticsService.mean(
      AnalyticsService.sleepValues(diaryEntries),
    );
    final avgIndex = AnalyticsService.calculateAverageCompositeIndex(
      diaryEntries,
    );
    final signals = AnalyticsService.generateSignals(diaryEntries, testResults);

    buf.writeln(_row(['avgFatigue', avgFatigue?.toStringAsFixed(2) ?? '']));
    buf.writeln(_row(['avgPain', avgPain?.toStringAsFixed(2) ?? '']));
    buf.writeln(_row(['avgMood', avgMood?.toStringAsFixed(2) ?? '']));
    buf.writeln(_row(['avgSleep', avgSleep?.toStringAsFixed(2) ?? '']));
    buf.writeln(
      _row(['avgCompositeIndex', avgIndex?.toStringAsFixed(1) ?? '']),
    );
    buf.writeln(_row(['activeSignalsCount', signals.length.toString()]));
    buf.writeln(
      _row(['activeSignalTitles', signals.map((s) => s.title).join('; ')]),
    );
    buf.writeln();

    // ── Active signals ─────────────────────────────────────────────────────
    buf.writeln('## ACTIVE SIGNALS');
    buf.writeln(_row(['date', 'severity', 'title', 'description']));
    for (final s in signals) {
      buf.writeln(
        _row([_formatDateTime(s.dateTime), s.severity, s.title, s.description]),
      );
    }

    return buf.toString();
  }

  // ── Report export ───────────────────────────────────────────────────────

  static Future<ExportedReport> exportCsv({
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
    return ExportedReport(
      filename: _reportFilename('csv'),
      bytes: Uint8List.fromList(utf8.encode(content)),
      mimeType: 'text/csv',
    );
  }

  static Future<ExportedReport> exportPdf({
    required UserProfile? profile,
    required List<DiaryEntry> diaryEntries,
    required List<TestResult> testResults,
    required String periodLabel,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    final now = DateTime.now();
    final sortedDiary = List<DiaryEntry>.from(diaryEntries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final sortedTests = List<TestResult>.from(testResults)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final signals = AnalyticsService.generateSignals(diaryEntries, testResults);

    final avgFatigue = AnalyticsService.mean(
      AnalyticsService.fatigueValues(diaryEntries),
    );
    final avgPain = AnalyticsService.mean(
      AnalyticsService.painValues(diaryEntries),
    );
    final avgMood = AnalyticsService.mean(
      AnalyticsService.moodValues(diaryEntries),
    );
    final avgSleep = AnalyticsService.mean(
      AnalyticsService.sleepValues(diaryEntries),
    );
    final avgIndex = AnalyticsService.calculateAverageCompositeIndex(
      diaryEntries,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 32, 28, 32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _pdfHeader(periodLabel: periodLabel, exportDate: now),
          _pdfSectionTitle('Пациент'),
          _pdfKeyValueTable([
            MapEntry('Имя', _blank(profile?.name ?? '')),
            MapEntry('Email', _blank(profile?.email ?? '')),
            if (profile != null)
              MapEntry(
                'Начало наблюдения',
                _formatHumanDate(profile.observationStartDate),
              ),
          ]),
          _pdfSectionTitle('Сводка'),
          _pdfKeyValueTable([
            MapEntry('Записи дневника', sortedDiary.length.toString()),
            MapEntry('Тесты', sortedTests.length.toString()),
            MapEntry('Средняя усталость', _fixed(avgFatigue, 2)),
            MapEntry('Средняя боль', _fixed(avgPain, 2)),
            MapEntry('Среднее настроение', _fixed(avgMood, 2)),
            MapEntry(
              'Средний сон',
              avgSleep == null ? '-' : '${_fixed(avgSleep, 1)} ч',
            ),
            MapEntry(
              'Средний индекс состояния',
              avgIndex == null ? '-' : avgIndex.toStringAsFixed(1),
            ),
            MapEntry('Активные сигналы', signals.length.toString()),
          ]),
          _pdfSectionTitle('Записи дневника'),
          if (sortedDiary.isEmpty)
            _pdfEmpty('За выбранный период записей дневника нет.')
          else
            _pdfTable(
              headers: const [
                'Дата',
                'Уст.',
                'Боль',
                'Настр.',
                'Чувст.',
                'Коорд.',
                'Зрен.',
                'Слаб.',
                'Стр.',
                'Сон',
                'Обостр.',
                'Заметка',
              ],
              rows: sortedDiary
                  .map(
                    (entry) => [
                      _formatHumanDate(entry.dateTime),
                      entry.fatigue.toString(),
                      entry.pain.toString(),
                      entry.mood.toString(),
                      entry.numbness.toString(),
                      entry.coordination.toString(),
                      entry.vision.toString(),
                      entry.weakness.toString(),
                      entry.stress.toString(),
                      entry.sleepHours.toStringAsFixed(1),
                      entry.flareFlag ? 'Да' : 'Нет',
                      _blank(entry.note),
                    ],
                  )
                  .toList(),
              columnWidths: const {
                0: pw.FixedColumnWidth(58),
                1: pw.FixedColumnWidth(32),
                2: pw.FixedColumnWidth(32),
                3: pw.FixedColumnWidth(40),
                4: pw.FixedColumnWidth(34),
                5: pw.FixedColumnWidth(34),
                6: pw.FixedColumnWidth(34),
                7: pw.FixedColumnWidth(34),
                8: pw.FixedColumnWidth(28),
                9: pw.FixedColumnWidth(34),
                10: pw.FixedColumnWidth(44),
              },
            ),
          _pdfSectionTitle('Результаты тестов'),
          if (sortedTests.isEmpty)
            _pdfEmpty('За выбранный период результатов тестов нет.')
          else
            _pdfTable(
              headers: const [
                'Дата',
                'Тест',
                'Значение',
                'Длительность',
                'Рука',
              ],
              rows: sortedTests.map(_testPdfRow).toList(),
              columnWidths: const {
                0: pw.FixedColumnWidth(82),
                1: pw.FixedColumnWidth(70),
                2: pw.FixedColumnWidth(80),
                3: pw.FixedColumnWidth(76),
                4: pw.FixedColumnWidth(48),
              },
            ),
          _pdfSectionTitle('Сигналы'),
          if (signals.isEmpty)
            _pdfEmpty('Активных сигналов за выбранный период нет.')
          else
            _pdfTable(
              headers: const ['Дата', 'Уровень', 'Сигнал', 'Описание'],
              rows: signals
                  .map(
                    (signal) => [
                      _formatHumanDateTime(signal.dateTime),
                      _severityLabel(signal.severity),
                      signal.title,
                      signal.description,
                    ],
                  )
                  .toList(),
              columnWidths: const {
                0: pw.FixedColumnWidth(82),
                1: pw.FixedColumnWidth(54),
                2: pw.FixedColumnWidth(96),
              },
            ),
        ],
      ),
    );

    return ExportedReport(
      filename: _reportFilename('pdf'),
      bytes: await doc.save(),
      mimeType: 'application/pdf',
    );
  }

  static pw.Widget _pdfHeader({
    required String periodLabel,
    required DateTime exportDate,
  }) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 18),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'NeuroLife',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Отчёт пациента',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Период: $periodLabel · Экспорт: ${_formatHumanDateTime(exportDate)}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    ),
  );

  static pw.Widget _pdfSectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _pdfEmpty(String text) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
    ),
  );

  static pw.Widget _pdfKeyValueTable(List<MapEntry<String, String>> rows) =>
      _pdfTable(
        headers: const ['Показатель', 'Значение'],
        rows: rows.map((row) => [row.key, row.value]).toList(),
        columnWidths: const {0: pw.FixedColumnWidth(150)},
      );

  static pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: columnWidths,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: headers
            .map((header) => _pdfCell(header, bold: true))
            .toList(),
      ),
      ...rows.map((row) => pw.TableRow(children: row.map(_pdfCell).toList())),
    ],
  );

  static pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  static List<String> _testPdfRow(TestResult result) {
    final isTapping = result.type == TestType.tapping;
    final value = isTapping
        ? '${result.value.toStringAsFixed(2)} тап/с'
        : '${result.value.toStringAsFixed(1)} мс';
    return [
      _formatHumanDateTime(result.dateTime),
      isTapping ? 'Таппинг' : 'Реакция',
      value,
      '${result.durationSeconds} сек',
      result.hand == TestHand.left
          ? 'Левая'
          : result.hand == TestHand.right
          ? 'Правая'
          : '-',
    ];
  }

  static String _severityLabel(String severity) {
    switch (severity) {
      case 'high':
        return 'Высокий';
      case 'warn':
        return 'Внимание';
      default:
        return 'Инфо';
    }
  }
}
