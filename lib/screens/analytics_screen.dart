import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/diary_provider.dart';
import '../models/diary_entry.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(bottom: false, child: const AnalyticsBody()),
    );
  }
}

class AnalyticsBody extends StatefulWidget {
  const AnalyticsBody({super.key});

  @override
  State<AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<AnalyticsBody> {
  String _period = '7 дней';

  int get _days => _period == '7 дней' ? 7 : _period == '30 дней' ? 30 : 90;

  // Entries for current period sorted oldest→newest.
  List<DiaryEntry> _currentEntries(DiaryProvider diary) {
    final e = AnalyticsService.entriesForLastDays(
        diary.diaryEntriesSorted, _days);
    return e..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Entries for the previous equal-length window sorted oldest→newest.
  List<DiaryEntry> _prevEntries(DiaryProvider diary) {
    final e = AnalyticsService.entriesForPreviousDays(
        diary.diaryEntriesSorted, _days);
    return e..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Up to 7 evenly-spaced x-axis date labels for the chart.
  List<String>? _xLabels(List<DiaryEntry> sorted) {
    if (sorted.length < 2) return null;
    if (sorted.length <= 7) {
      return sorted.map((e) => '${e.dateTime.day}').toList();
    }
    const maxLabels = 5;
    final n = sorted.length;
    final step = (n - 1) / (maxLabels - 1);
    return List.generate(maxLabels, (i) {
      final idx = (i * step).round().clamp(0, n - 1);
      return '${sorted[idx].dateTime.day}';
    });
  }

  String _fmt(double? v, {int decimals = 1}) =>
      v != null ? v.toStringAsFixed(decimals) : '-';

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final current = _currentEntries(diary);
    final prev = _prevEntries(diary);

    final fatigueVals = AnalyticsService.fatigueValues(current);
    final painVals = AnalyticsService.painValues(current);
    final moodVals = AnalyticsService.moodValues(current);

    final fatigueMean = AnalyticsService.mean(fatigueVals);
    final fatigueMedian = AnalyticsService.median(fatigueVals);
    final painMean = AnalyticsService.mean(painVals);
    final painSd = AnalyticsService.standardDeviation(painVals);
    final moodMean = AnalyticsService.mean(moodVals);
    final moodSd = AnalyticsService.standardDeviation(moodVals);

    final prevFatigueMean =
        AnalyticsService.mean(AnalyticsService.fatigueValues(prev));
    final prevPainMean =
        AnalyticsService.mean(AnalyticsService.painValues(prev));
    final prevMoodMean =
        AnalyticsService.mean(AnalyticsService.moodValues(prev));

    final fatigueDelta =
        AnalyticsService.percentChange(fatigueMean, prevFatigueMean);
    final painDelta =
        AnalyticsService.percentChange(painMean, prevPainMean);
    final moodDelta =
        AnalyticsService.percentChange(moodMean, prevMoodMean);

    // Comparison section uses fatigue as the primary metric.
    final compPrev = prevFatigueMean;
    final compCurrent = fatigueMean;
    final compDeltaAbs = (compCurrent != null && compPrev != null)
        ? compCurrent - compPrev
        : null;

    final hasData = current.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NLHeader(
            greeting: 'Анализ',
            title: 'Динамика',
            actions: [
              const SizedBox(width: 8),
              NLCircleBtn(
                  child: const Icon(Icons.download_outlined,
                      color: NLColors.ink, size: 18)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NLSegmented(
                  items: const ['7 дней', '30 дней', '90 дней'],
                  active: _period,
                  onChange: (v) => setState(() => _period = v),
                ),
                const SizedBox(height: 14),

                if (!hasData)
                  NLCard(
                    child: Column(
                      children: const [
                        Icon(Icons.bar_chart_rounded,
                            size: 36, color: NLColors.muted),
                        SizedBox(height: 10),
                        Text('Недостаточно данных для анализа',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: NLColors.ink)),
                        SizedBox(height: 4),
                        Text('Добавьте записи в дневник',
                            style:
                                TextStyle(fontSize: 13, color: NLColors.muted)),
                      ],
                    ),
                  )
                else ...[
                  // Усталость
                  NLCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: NLColors.peach,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    const Text('Усталость',
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: NLColors.ink)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Среднее ${_fmt(fatigueMean)} · медиана ${_fmt(fatigueMedian)}',
                                    style: const TextStyle(
                                        fontSize: 13, color: NLColors.muted),
                                  ),
                                ])),
                            if (fatigueDelta != null)
                              NLStat(delta: fatigueDelta.round()),
                          ]),
                          const SizedBox(height: 12),
                          if (fatigueVals.length >= 2)
                            NLChart(
                              data: fatigueVals,
                              threshold: 7,
                              color: NLColors.peach,
                              tinted: NLColors.peachSoft,
                              height: 120,
                              xLabels: _xLabels(current),
                            ),
                        ]),
                  ),
                  const SizedBox(height: 12),

                  // Боль
                  NLCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: NLColors.rose,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    const Text('Боль',
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: NLColors.ink)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Среднее ${_fmt(painMean)} · σ ${_fmt(painSd)}',
                                    style: const TextStyle(
                                        fontSize: 13, color: NLColors.muted),
                                  ),
                                ])),
                            if (painDelta != null)
                              NLStat(delta: painDelta.round()),
                          ]),
                          const SizedBox(height: 12),
                          if (painVals.length >= 2)
                            NLChart(
                              data: painVals,
                              color: NLColors.rose,
                              tinted: NLColors.roseSoft,
                              height: 100,
                              xLabels: _xLabels(current),
                            ),
                        ]),
                  ),
                  const SizedBox(height: 12),

                  // Настроение
                  NLCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: NLColors.accent,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    const Text('Настроение',
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: NLColors.ink)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Среднее ${_fmt(moodMean)} · σ ${_fmt(moodSd)}',
                                    style: const TextStyle(
                                        fontSize: 13, color: NLColors.muted),
                                  ),
                                ])),
                            // Negate: mood increase is good, NLStat treats positive as bad.
                            if (moodDelta != null)
                              NLStat(delta: (-moodDelta).round()),
                          ]),
                          const SizedBox(height: 12),
                          if (moodVals.length >= 2)
                            NLChart(
                              data: moodVals,
                              color: NLColors.accent,
                              tinted: NLColors.accentSoft,
                              height: 100,
                              xLabels: _xLabels(current),
                            ),
                        ]),
                  ),

                  const NLSectionTitle('Сравнение окон'),
                  NLCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Прошлые $_days дней',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: NLColors.muted)),
                                Text(
                                  _fmt(compPrev),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: NLColors.ink),
                                ),
                              ]),
                          const SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Последние $_days дней',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: NLColors.muted)),
                                Text(
                                  _fmt(compCurrent),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: NLColors.ink),
                                ),
                              ]),
                          const NLDivider(),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Δ среднее (усталость)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: NLColors.ink)),
                                Text(
                                  compDeltaAbs != null && fatigueDelta != null
                                      ? '${compDeltaAbs >= 0 ? '+' : ''}${_fmt(compDeltaAbs)} · ${fatigueDelta >= 0 ? '+' : ''}${fatigueDelta.round()}%'
                                      : '-',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: compDeltaAbs != null &&
                                              compDeltaAbs > 0
                                          ? NLColors.bad
                                          : NLColors.good),
                                ),
                              ]),
                        ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
