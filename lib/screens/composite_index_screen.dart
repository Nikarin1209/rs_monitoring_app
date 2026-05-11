import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/diary_provider.dart';
import '../services/analytics_service.dart';

class CompositeIndexScreen extends StatelessWidget {
  const CompositeIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();

    // Use last 30 days as the main window.
    final entries30 = AnalyticsService.entriesForLastDays(
        diary.diaryEntriesSorted, 30)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final avgFatigue =
        AnalyticsService.mean(AnalyticsService.fatigueValues(entries30));
    final avgPain =
        AnalyticsService.mean(AnalyticsService.painValues(entries30));
    final avgMood =
        AnalyticsService.mean(AnalyticsService.moodValues(entries30));

    final int? indexValue = (avgFatigue != null &&
            avgPain != null &&
            avgMood != null)
        ? AnalyticsService.calculateCompositeIndexFromAverages(
            fatigue: avgFatigue,
            pain: avgPain,
            mood: avgMood,
          )
        : null;

    // Weekly trend: avg last 7d vs prev 7d composite index.
    final last7 = AnalyticsService.entriesForLastDays(diary.diaryEntriesSorted, 7);
    final prev7 = AnalyticsService.entriesForPreviousDays(diary.diaryEntriesSorted, 7);
    final last7Avg = AnalyticsService.calculateAverageCompositeIndex(last7);
    final prev7Avg = AnalyticsService.calculateAverageCompositeIndex(prev7);
    final weeklyDelta =
        AnalyticsService.percentChange(last7Avg, prev7Avg);

    // Chart data: per-entry composite index / 10 to fit 0–10 NLChart scale.
    final chartData = entries30
        .map((e) =>
            (AnalyticsService.calculateCompositeIndexFromEntry(e) ?? 0) / 10.0)
        .toList();

    final ringValue = indexValue?.toDouble() ?? 0;
    final ringColor = indexValue == null
        ? NLColors.muted
        : indexValue >= 70
            ? NLColors.good
            : indexValue >= 45
                ? NLColors.warn
                : NLColors.bad;

    String fmt(double? v, {int decimals = 1}) =>
        v != null ? v.toStringAsFixed(decimals) : '-';

    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            children: [
              NLTopBar(leading: NLBackBtn(), title: 'Индекс состояния'),
              const SizedBox(height: 8),
              // Ring
              SizedBox(
                height: 224,
                child: Stack(alignment: Alignment.center, children: [
                  NLRing(
                      value: ringValue,
                      size: 200,
                      stroke: 16,
                      color: ringColor),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      indexValue != null ? '$indexValue' : '-',
                      style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                          color: NLColors.ink,
                          height: 1),
                    ),
                    const Text('из 100',
                        style:
                            TextStyle(fontSize: 13, color: NLColors.muted)),
                    const SizedBox(height: 6),
                    if (weeklyDelta != null)
                      // Negate: index up = good → green
                      NLStat(
                          delta: (-weeklyDelta).round(),
                          unit: '% за нед.')
                    else
                      const SizedBox(height: 22),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NLCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Состав индекса',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: NLColors.ink)),
                            const SizedBox(height: 14),
                            _ComponentRow(
                                label: 'Усталость',
                                weight: 0.4,
                                value: avgFatigue ?? 0,
                                displayValue: fmt(avgFatigue),
                                color: NLColors.peach),
                            const SizedBox(height: 14),
                            _ComponentRow(
                                label: 'Боль',
                                weight: 0.3,
                                value: avgPain ?? 0,
                                displayValue: fmt(avgPain),
                                color: NLColors.rose),
                            const SizedBox(height: 14),
                            _ComponentRow(
                                label: 'Настроение',
                                weight: 0.3,
                                value: avgMood ?? 0,
                                displayValue: fmt(avgMood),
                                color: NLColors.accent),
                            const NLDivider(),
                            const Text(
                              'Индекс является инструментом самоконтроля и не является медицинским диагнозом.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: NLColors.muted,
                                  height: 1.5),
                            ),
                          ]),
                    ),
                    const NLSectionTitle('Индекс за 30 дней'),
                    NLCard(
                      child: chartData.length >= 2
                          ? NLChart(
                              data: chartData,
                              // 50/100 threshold scaled to 0–10
                              threshold: 5,
                              height: 140,
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Text(
                                  'Недостаточно данных для графика',
                                  style: TextStyle(
                                      fontSize: 13, color: NLColors.muted),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComponentRow extends StatelessWidget {
  final String label;
  final double weight;
  final double value;
  final String displayValue;
  final Color color;

  const _ComponentRow({
    required this.label,
    required this.weight,
    required this.value,
    required this.displayValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: NLColors.ink)),
        Text('вес $weight · $displayValue/10',
            style: const TextStyle(fontSize: 13, color: NLColors.muted)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 6,
          child: Stack(children: [
            Container(color: NLColors.surface2),
            FractionallySizedBox(
              widthFactor: (value / 10).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: color),
            ),
          ]),
        ),
      ),
    ]);
  }
}
