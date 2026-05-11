import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/diary_provider.dart';
import '../state/profile_provider.dart';
import '../state/test_results_provider.dart';
import '../models/test_result.dart';
import 'diary_entry_screen.dart';
import 'history_list_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'tapping_test_screen.dart';
import 'reaction_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _keys = ['home', 'diary', 'chart', 'profile'];

  Widget _body() {
    switch (_tab) {
      case 1: return const HistoryListBody();
      case 2: return const AnalyticsBody();
      case 3: return const SettingsBody();
      default: return const _HomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NLColors.bg,
      body: Stack(
        children: [
          _body(),
          NLTabBar(
            active: _keys[_tab],
            onTabChanged: (key) => setState(() => _tab = _keys.indexOf(key)),
            onFab: () {
              final today = context.read<DiaryProvider>().todayDiaryEntry;
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DiaryEntryScreen(entry: today)));
            },
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatHeaderDate(DateTime dt) {
  const weekdays = ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
  const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
  return '${weekdays[dt.weekday % 7]} · ${dt.day} ${months[dt.month - 1]}';
}

int? _calcConditionIndex(DiaryProvider diary) {
  final avgFatigue = diary.averageLastDays((e) => e.fatigue.toDouble(), 7);
  final avgPain = diary.averageLastDays((e) => e.pain.toDouble(), 7);
  final avgMood = diary.averageLastDays((e) => e.mood.toDouble(), 7);
  if (avgFatigue == null || avgPain == null || avgMood == null) return null;
  final fatigueNorm = avgFatigue / 10;
  final painNorm = avgPain / 10;
  final moodBadNorm = 1 - avgMood / 10;
  final scoreBad = 0.4 * fatigueNorm + 0.3 * painNorm + 0.3 * moodBadNorm;
  return ((1 - scoreBad) * 100).round();
}

class _Signal {
  final String title;
  final String body;
  final NLSignalLevel level;
  const _Signal(this.title, this.body, this.level);
}

_Signal? _calcWarningSignal(DiaryProvider diary, TestResultsProvider tests) {
  if (!diary.hasAnyData) return null;

  // Fatigue >= 7 for 3 consecutive recent entries
  final recent = diary.diaryEntriesSorted.take(3).toList();
  if (recent.length >= 3 && recent.every((e) => e.fatigue >= 7)) {
    return const _Signal(
      'Возможный сигнал ухудшения',
      'Высокая усталость ≥ 7 баллов несколько дней подряд. Следите за состоянием и при необходимости обсудите изменения с врачом.',
      NLSignalLevel.warn,
    );
  }

  // Average fatigue up >= 20% vs previous 7 days
  final fatigueDelta = diary.percentChange((e) => e.fatigue.toDouble(), 7);
  if (fatigueDelta != null && fatigueDelta >= 20) {
    return const _Signal(
      'Возможный сигнал ухудшения',
      'Средняя усталость за 7 дней выросла. Следите за состоянием и при необходимости обсудите изменения с врачом.',
      NLSignalLevel.warn,
    );
  }

  // Average pain up >= 20% vs previous 7 days
  final painDelta = diary.percentChange((e) => e.pain.toDouble(), 7);
  if (painDelta != null && painDelta >= 20) {
    return const _Signal(
      'Возможный сигнал ухудшения',
      'Средняя боль за 7 дней выросла. Следите за состоянием и при необходимости обсудите изменения с врачом.',
      NLSignalLevel.warn,
    );
  }

  // Reaction time increased >= 15% (compare newest half vs older half of last 4+ results)
  final reactionResults =
      tests.results.where((r) => r.type == TestType.reaction).toList();
  if (reactionResults.length >= 4) {
    final half = reactionResults.length ~/ 2;
    final recentAvg =
        reactionResults.take(half).fold<double>(0, (s, r) => s + r.value) / half;
    final prevAvg =
        reactionResults.skip(half).take(half).fold<double>(0, (s, r) => s + r.value) / half;
    if (prevAvg > 0 && (recentAvg - prevAvg) / prevAvg >= 0.15) {
      return const _Signal(
        'Возможный сигнал ухудшения',
        'Время реакции увеличивается. Следите за состоянием и при необходимости обсудите изменения с врачом.',
        NLSignalLevel.warn,
      );
    }
  }

  return null;
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final diary = context.watch<DiaryProvider>();
    final tests = context.watch<TestResultsProvider>();

    final now = DateTime.now();
    final greeting =
        profile.hasProfile ? 'Привет, ${profile.profile!.name}' : 'Привет';
    final avatarLetter = profile.avatarLetter;

    final avgFatigue = diary.averageLastDays((e) => e.fatigue.toDouble(), 7);
    final avgPain = diary.averageLastDays((e) => e.pain.toDouble(), 7);
    final avgMood = diary.averageLastDays((e) => e.mood.toDouble(), 7);
    final avgSleep = diary.averageLastDays((e) => e.sleepHours, 7);

    final fatigueDelta = diary.percentChange((e) => e.fatigue.toDouble(), 7);
    final painDelta = diary.percentChange((e) => e.pain.toDouble(), 7);
    final moodDelta = diary.percentChange((e) => e.mood.toDouble(), 7);
    final sleepDelta = diary.percentChange((e) => e.sleepHours, 7);

    final conditionIndex = _calcConditionIndex(diary);
    final signal = _calcWarningSignal(diary, tests);

    final tapping = tests.latestTappingResult;
    final reaction = tests.latestReactionResult;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NLHeader(
              greeting: _formatHeaderDate(now),
              title: greeting,
              actions: [
                const SizedBox(width: 8),
                Stack(
                  children: [
                    NLCircleBtn(
                        child: const Icon(Icons.notifications_outlined,
                            color: NLColors.ink, size: 18)),
                    Positioned(
                      top: 8,
                      right: 9,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: NLColors.bad,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: NLColors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                NLAvatar(avatarLetter),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TodayCard(diary: diary),
                  const NLSectionTitle('Сводка за 7 дней'),
                  if (!diary.hasAnyData)
                    _EmptyDataCard()
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: NLTile(
                            label: 'Усталость',
                            value: avgFatigue != null
                                ? avgFatigue.toStringAsFixed(1)
                                : '-',
                            unit: '/10',
                            badge: fatigueDelta != null
                                ? NLStat(delta: fatigueDelta.round())
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NLTile(
                            label: 'Боль',
                            value: avgPain != null
                                ? avgPain.toStringAsFixed(1)
                                : '-',
                            unit: '/10',
                            badge: painDelta != null
                                ? NLStat(delta: painDelta.round())
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NLTile(
                            label: 'Настроение',
                            value: avgMood != null
                                ? avgMood.toStringAsFixed(1)
                                : '-',
                            unit: '/10',
                            // negate: mood increase is good, NLStat treats positive as bad
                            badge: moodDelta != null
                                ? NLStat(delta: (-moodDelta).round())
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NLTile(
                            label: 'Сон',
                            value: avgSleep != null
                                ? avgSleep.toStringAsFixed(1)
                                : '-',
                            unit: 'ч',
                            // negate: sleep increase is good
                            badge: sleepDelta != null
                                ? NLStat(delta: (-sleepDelta).round())
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (conditionIndex != null) ...[
                      const SizedBox(height: 8),
                      _ConditionIndexCard(index: conditionIndex),
                    ],
                  ],
                  const NLSectionTitle('Сигнал', action: 'Все →'),
                  signal != null
                      ? NLSignalRow(
                          title: signal.title,
                          body: signal.body,
                          level: signal.level,
                        )
                      : NLSignalRow(
                          title: 'Активных сигналов нет',
                          body: diary.hasAnyData
                              ? 'Продолжайте вести дневник для отслеживания изменений.'
                              : 'Создайте первую запись дневника, чтобы начать мониторинг.',
                          level: NLSignalLevel.info,
                        ),
                  const NLSectionTitle('Тесты на сегодня'),
                  NLList(children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TappingTestScreen())),
                      child: NLListRow(
                        icon: const Icon(Icons.ads_click_rounded,
                            color: NLColors.accent, size: 18),
                        iconBg: NLColors.accentSoft,
                        title: 'Таппинг-тест',
                        sub: tapping != null
                            ? 'Последний: ${tapping.value.toStringAsFixed(1)} уд/с'
                            : 'Моторика · 10 секунд',
                        right: const Icon(Icons.chevron_right_rounded,
                            color: NLColors.muted, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ReactionTestScreen())),
                      child: NLListRow(
                        icon: const Icon(Icons.bolt_rounded,
                            color: NLColors.peach, size: 18),
                        iconBg: NLColors.peachSoft,
                        title: 'Тест реакции',
                        sub: reaction != null
                            ? 'Последний: ${reaction.value.round()} мс'
                            : '5 попыток · 30 секунд',
                        last: true,
                        right: const Icon(Icons.chevron_right_rounded,
                            color: NLColors.muted, size: 20),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Today Card ──────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final DiaryProvider diary;
  const _TodayCard({required this.diary});

  @override
  Widget build(BuildContext context) {
    final entry = diary.todayDiaryEntry;

    if (entry != null) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DiaryEntryScreen(entry: entry))),
        child: NLCard(
          color: NLColors.mintSoft,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('СЕГОДНЯ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NLColors.good,
                            letterSpacing: 1.1)),
                    const SizedBox(height: 4),
                    const Text('Запись сделана',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: NLColors.ink)),
                    const SizedBox(height: 4),
                    Text(
                      'Усталость ${entry.fatigue} · Боль ${entry.pain} · Настроение ${entry.mood}',
                      style: const TextStyle(fontSize: 13, color: NLColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: NLColors.ink,
                    borderRadius: BorderRadius.circular(999)),
                child: Row(children: const [
                  Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Изменить',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ]),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DiaryEntryScreen())),
      child: NLCard(
        color: NLColors.accentSoft,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('СЕГОДНЯ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NLColors.accent,
                          letterSpacing: 1.1)),
                  SizedBox(height: 4),
                  Text('Запись не сделана',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: NLColors.ink)),
                  SizedBox(height: 4),
                  Text('Займёт около 30 секунд',
                      style: TextStyle(fontSize: 13, color: NLColors.muted)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: NLColors.ink,
                  borderRadius: BorderRadius.circular(999)),
              child: Row(children: const [
                Icon(Icons.add, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('Заполнить',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Condition Index Card ─────────────────────────────────────────────────────

class _ConditionIndexCard extends StatelessWidget {
  final int index;
  const _ConditionIndexCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (index >= 70) {
      color = NLColors.good;
      label = 'Хорошее';
    } else if (index >= 45) {
      color = NLColors.warn;
      label = 'Умеренное';
    } else {
      color = NLColors.bad;
      label = 'Требует внимания';
    }

    return NLCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ИНДЕКС СОСТОЯНИЯ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NLColors.muted,
                        letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$index',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: -0.5)),
                    const SizedBox(width: 4),
                    const Text('/100',
                        style: TextStyle(
                            fontSize: 14,
                            color: NLColors.muted,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State Card ─────────────────────────────────────────────────────────

class _EmptyDataCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NLCard(
      child: Column(
        children: const [
          Icon(Icons.bar_chart_rounded, size: 36, color: NLColors.muted),
          SizedBox(height: 10),
          Text('Пока нет данных для анализа',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: NLColors.ink)),
          SizedBox(height: 4),
          Text('Создайте первую запись дневника',
              style: TextStyle(fontSize: 13, color: NLColors.muted)),
        ],
      ),
    );
  }
}
