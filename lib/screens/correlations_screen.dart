import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/diary_provider.dart';
import '../services/analytics_service.dart';

class CorrelationsScreen extends StatelessWidget {
  const CorrelationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final entries = diary.diaryEntriesSorted;

    final sleep = AnalyticsService.sleepValues(entries);
    final fatigue = AnalyticsService.fatigueValues(entries);
    final mood = AnalyticsService.moodValues(entries);
    final pain = AnalyticsService.painValues(entries);

    final hasEnough = entries.length >= 5;

    final rSleepFatigue =
        hasEnough ? AnalyticsService.spearmanCorrelation(sleep, fatigue) : null;
    final rSleepMood =
        hasEnough ? AnalyticsService.spearmanCorrelation(sleep, mood) : null;
    final rPainMood =
        hasEnough ? AnalyticsService.spearmanCorrelation(pain, mood) : null;

    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            children: [
              NLTopBar(leading: NLBackBtn(), title: 'Взаимосвязи'),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Что связано',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            color: NLColors.ink)),
                    const SizedBox(height: 6),
                    const Text(
                      'Корреляция Спирмена. Это связь, не причина.',
                      style: TextStyle(
                          fontSize: 14,
                          color: NLColors.muted,
                          height: 1.5),
                    ),
                    const SizedBox(height: 22),

                    if (!hasEnough)
                      NLCard(
                        child: Column(children: const [
                          Icon(Icons.show_chart_rounded,
                              size: 36, color: NLColors.muted),
                          SizedBox(height: 10),
                          Text(
                            'Недостаточно данных для анализа взаимосвязей.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: NLColors.ink),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Нужно не менее 5 записей в дневнике.',
                            style:
                                TextStyle(fontSize: 13, color: NLColors.muted),
                          ),
                        ]),
                      )
                    else ...[
                      _CorrCard(
                          a: 'Сон',
                          b: 'Усталость',
                          r: rSleepFatigue),
                      const SizedBox(height: 10),
                      _CorrCard(
                          a: 'Сон',
                          b: 'Настроение',
                          r: rSleepMood),
                      const SizedBox(height: 10),
                      _CorrCard(
                          a: 'Боль',
                          b: 'Настроение',
                          r: rPainMood),
                    ],

                    const SizedBox(height: 8),
                    const Text(
                      'Корреляция от −1 до +1. |r| > 0.5 — заметная связь.\n'
                      'Корреляция показывает связь между показателями, но не доказывает причину.',
                      style: TextStyle(
                          fontSize: 12, color: NLColors.muted, height: 1.5),
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

class _CorrCard extends StatelessWidget {
  final String a;
  final String b;
  final double? r;

  const _CorrCard({required this.a, required this.b, required this.r});

  @override
  Widget build(BuildContext context) {
    if (r == null) {
      return NLCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _PairChip(a),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child:
                  Text('↔', style: TextStyle(fontSize: 16, color: NLColors.muted)),
            ),
            _PairChip(b),
          ]),
          const SizedBox(height: 10),
          const Text('Недостаточно данных',
              style: TextStyle(fontSize: 12, color: NLColors.muted)),
        ]),
      );
    }

    final label = AnalyticsService.correlationLabel(r!);
    final sign = AnalyticsService.correlationSign(r!);
    final prefix = r! > 0 ? '+' : '';

    return NLCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _PairChip(a),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child:
                Text('↔', style: TextStyle(fontSize: 16, color: NLColors.muted)),
          ),
          _PairChip(b),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: NLCorrelationBar(r: r!)),
          const SizedBox(width: 12),
          Text(
            '$prefix${r!.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: NLColors.ink),
          ),
        ]),
        const SizedBox(height: 8),
        Text('$sign · $label',
            style: const TextStyle(fontSize: 12, color: NLColors.muted)),
      ]),
    );
  }
}

class _PairChip extends StatelessWidget {
  final String label;
  const _PairChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: NLColors.surface2,
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NLColors.ink)),
    );
  }
}
