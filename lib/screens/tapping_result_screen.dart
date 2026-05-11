import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../models/test_result.dart';
import '../state/test_results_provider.dart';
import 'tapping_test_screen.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Average taps/sec for results in the 7-day window before the last 7 days.
double? _prevPeriodAvg(TestResultsProvider tests) {
  final now = DateTime.now();
  final mid = now.subtract(const Duration(days: 7));
  final start = now.subtract(const Duration(days: 14));
  final subset = tests.results
      .where((r) =>
          r.type == TestType.tapping &&
          !r.dateTime.isBefore(start) &&
          r.dateTime.isBefore(mid))
      .toList();
  if (subset.isEmpty) return null;
  return subset.fold<double>(0, (s, r) => s + r.value) / subset.length;
}

/// Percent change between two averages. Returns null if either is missing/zero.
double? _percentChange(double? current, double? previous) {
  if (current == null || previous == null || previous == 0) return null;
  return (current - previous) / previous * 100;
}

/// Colored arrow badge for the change tile.
/// For tapping, positive change is good (more taps = better motor function).
Widget _changeBadge(double? pct) {
  if (pct == null) return const SizedBox.shrink();
  final isGood = pct >= 0;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: isGood ? NLColors.mintSoft : NLColors.roseSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      isGood ? '↑' : '↓',
      style: TextStyle(
          color: isGood ? NLColors.good : NLColors.bad,
          fontSize: 12,
          fontWeight: FontWeight.w700),
    ),
  );
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class TappingResultScreen extends StatelessWidget {
  const TappingResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<TestResultsProvider>();
    final current = tests.latestTappingResult;

    // Total taps for current result (value is stored as taps/sec)
    final totalTaps = current != null
        ? (current.value * current.durationSeconds).round()
        : 0;

    // 7-day average in taps/sec → convert to total taps for display
    final avg7 = tests.averageLastDays(TestType.tapping, 7);
    final avg7Taps = avg7 != null ? (avg7 * 10).round() : null;

    // Percent change vs previous 7-day window
    final prev7 = _prevPeriodAvg(tests);
    final pct = _percentChange(avg7, prev7);
    final pctStr =
        pct != null ? '${pct >= 0 ? '+' : ''}${pct.round()}%' : '–';

    // Chart: last 7 tapping results in chronological order.
    // Values (taps/sec, range ~4–8) fit the NLChart's internal 0–10 scale.
    final allTapping = tests.results
        .where((r) => r.type == TestType.tapping)
        .toList(); // already newest-first
    final chartEntries = allTapping.take(7).toList().reversed.toList();
    final chartData = chartEntries.map((r) => r.value).toList();
    final xLabels = chartEntries
        .map((r) => '${r.dateTime.day}')
        .toList();

    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NLTopBar(
              leading: NLBackBtn(),
              title: 'Результат',
              trailing: const Text('Готово',
                  style:
                      TextStyle(fontSize: 14, color: NLColors.muted)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    // Ring + total taps
                    SizedBox(
                      height: 180,
                      child: Stack(alignment: Alignment.center, children: [
                        NLRing(
                          value: totalTaps.toDouble(),
                          max: 80,
                          size: 180,
                          stroke: 14,
                          color: NLColors.accent,
                        ),
                        Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$totalTaps',
                                style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -2,
                                    color: NLColors.ink,
                                    height: 1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'нажатий за ${current?.durationSeconds ?? 10} сек',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: NLColors.muted),
                              ),
                            ]),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    // Summary tiles
                    Row(children: [
                      Expanded(
                        child: NLTile(
                          label: 'Среднее (7д)',
                          value: avg7Taps != null ? '$avg7Taps' : '–',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NLTile(
                          label: 'Изменение',
                          value: pctStr,
                          badge: _changeBadge(pct),
                        ),
                      ),
                    ]),
                    // Dynamics chart — only shown when 2+ results exist
                    if (chartData.length >= 2) ...[
                      const NLSectionTitle('Динамика'),
                      NLCard(
                        child: NLChart(
                          data: chartData,
                          // 5.0 taps/sec = 50 taps in 10 s — reference line
                          threshold: 5.0,
                          height: 120,
                          xLabels: xLabels,
                        ),
                      ),
                    ] else ...[
                      const NLSectionTitle('Динамика'),
                      NLCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(children: const [
                            Icon(Icons.show_chart_rounded,
                                size: 32, color: NLColors.muted),
                            SizedBox(height: 8),
                            Text('Недостаточно данных',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: NLColors.muted)),
                            SizedBox(height: 4),
                            Text('Пройдите ещё несколько тестов',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: NLColors.muted)),
                          ]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    NLButton(
                      label: 'Повторить тест',
                      full: true,
                      onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const TappingTestScreen())),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
