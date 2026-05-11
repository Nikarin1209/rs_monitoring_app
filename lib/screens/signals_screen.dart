import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/diary_provider.dart';
import '../state/test_results_provider.dart';
import '../services/analytics_service.dart';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  String _tab = 'Активные';

  NLSignalLevel _level(String severity) {
    if (severity == 'high') return NLSignalLevel.bad;
    if (severity == 'warn') return NLSignalLevel.warn;
    return NLSignalLevel.info;
  }

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final tests = context.watch<TestResultsProvider>();

    final signals = AnalyticsService.generateSignals(
      diary.diaryEntriesSorted,
      tests.results,
    );

    // Entries for the fatigue-streak detail widget (latest 3, newest first).
    final top3 = diary.diaryEntriesSorted.take(3).toList();
    final hasStreakSignal =
        signals.any((s) => s.severity == 'high');

    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NLHeader(greeting: 'Система обнаружила', title: 'Сигналы'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NLSegmented(
                      items: const ['Активные', 'Архив'],
                      active: _tab,
                      onChange: (v) => setState(() => _tab = v),
                    ),
                    const SizedBox(height: 14),

                    if (_tab == 'Архив')
                      const _EmptyState(
                        icon: Icons.archive_outlined,
                        message: 'Архив пуст',
                        sub: 'Прошлые сигналы здесь не отображаются.',
                      )
                    else if (signals.isEmpty)
                      const _EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        message: 'Активных сигналов нет',
                        sub:
                            'Продолжайте вести дневник для отслеживания изменений.',
                      )
                    else ...[
                      // High-priority alert card (fatigue streak).
                      if (hasStreakSignal && top3.length >= 3) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NLColors.surface,
                            borderRadius:
                                BorderRadius.all(NLRadius.lg),
                            border: Border.all(
                                color: NLColors.bad, width: 1.5),
                            boxShadow: shadowCard,
                          ),
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: NLColors.roseSoft,
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: const Text('Высокий',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: NLColors.bad)),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                const Text('Усталость ≥ 7 три дня подряд',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: NLColors.ink)),
                                const SizedBox(height: 6),
                                const Text(
                                  'Усталость ≥ 7 в течение 3 записей подряд. '
                                  'Следите за состоянием и при необходимости '
                                  'обсудите изменения с врачом.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: NLColors.muted,
                                      height: 1.5),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: NLColors.roseSoft,
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: top3.reversed
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final e = entry.value;
                                      final isLast =
                                          entry.key ==
                                              top3.length - 1;
                                      final day = e.dateTime.day;
                                      final months = [
                                        'янв','фев','мар','апр','май',
                                        'июн','июл','авг','сен','окт',
                                        'ноя','дек'
                                      ];
                                      final mon =
                                          months[e.dateTime.month - 1];
                                      return _DayValue(
                                        date: '$day $mon',
                                        value: '${e.fatigue}',
                                        highlight: isLast,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ]),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Remaining (non-high) signals.
                      ...signals
                          .where((s) => s.severity != 'high')
                          .map((s) => NLSignalRow(
                                title: s.title,
                                body: s.description,
                                level: _level(s.severity),
                                trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: NLColors.muted,
                                    size: 20),
                              )),
                    ],

                    const NLSectionTitle('Правила обнаружения'),
                    NLList(children: [
                      NLListRow(
                        icon: const Icon(Icons.ads_click_rounded,
                            size: 16, color: NLColors.accent),
                        iconBg: NLColors.accentSoft,
                        title: 'Порог · 3 дня подряд',
                        sub: 'Усталость ≥ 7',
                        right: const Text('Вкл',
                            style: TextStyle(
                                fontSize: 14, color: NLColors.muted)),
                      ),
                      NLListRow(
                        icon: const Icon(Icons.arrow_upward_rounded,
                            size: 16, color: NLColors.peach),
                        iconBg: NLColors.peachSoft,
                        title: 'Прирост среднего',
                        sub: 'Δ ≥ 20% к прошлой неделе',
                        right: const Text('Вкл',
                            style: TextStyle(
                                fontSize: 14, color: NLColors.muted)),
                      ),
                      NLListRow(
                        icon: const Icon(Icons.timer_outlined,
                            size: 16, color: NLColors.rose),
                        iconBg: NLColors.roseSoft,
                        title: 'Реакция замедлилась',
                        sub: 'Медиана ≥ +15%',
                        last: true,
                        right: const Text('Вкл',
                            style: TextStyle(
                                fontSize: 14, color: NLColors.muted)),
                      ),
                    ]),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return NLCard(
      child: Column(children: [
        Icon(icon, size: 36, color: NLColors.muted),
        const SizedBox(height: 10),
        Text(message,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: NLColors.ink)),
        const SizedBox(height: 4),
        Text(sub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: NLColors.muted)),
      ]),
    );
  }
}

class _DayValue extends StatelessWidget {
  final String date;
  final String value;
  final bool highlight;
  const _DayValue(
      {required this.date, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(date,
          style: const TextStyle(fontSize: 12, color: NLColors.ink2)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: highlight ? NLColors.bad : NLColors.ink)),
    ]);
  }
}
