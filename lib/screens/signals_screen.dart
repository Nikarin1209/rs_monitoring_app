import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/diary_provider.dart';
import '../state/profile_provider.dart';
import '../state/test_results_provider.dart';
import '../services/analytics_service.dart';
import '../services/supabase_service.dart';

class SignalsScreen extends StatefulWidget {
  final String initialTab;

  const SignalsScreen({super.key, this.initialTab = 'Активные'});

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  late String _tab;
  final Set<String> _sentSignalKeys = {};
  final Set<String> _sentEpisodeKeys = {};

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  NLSignalLevel _level(String severity) {
    if (severity == 'high') return NLSignalLevel.bad;
    if (severity == 'warn') return NLSignalLevel.warn;
    return NLSignalLevel.info;
  }

  String _signalKey(AnalysisSignal signal) =>
      '${signal.title}|${signal.description}';

  String _episodeKey(DeteriorationEpisode episode) => episode.id;

  Future<void> _sendToDoctor(AnalysisSignal signal) async {
    final profile = context.read<ProfileProvider>().profile;
    if (profile?.doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите лечащего врача в профиле.')),
      );
      return;
    }

    final key = _signalKey(signal);
    final text =
        'Сигнал мониторинга: ${signal.title}\n'
        '${signal.description}\n\n'
        'Отправлено пациентом из раздела "Сигналы".';

    try {
      await SupabaseService.sendChatMessage(
        receiverId: profile!.doctorId!,
        body: text,
      );
      if (!mounted) return;
      setState(() => _sentSignalKeys.add(key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сигнал отправлен врачу в чат.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отправить сигнал врачу.')),
      );
    }
  }

  Future<void> _sendEpisodeToDoctor(DeteriorationEpisode episode) async {
    final profile = context.read<ProfileProvider>().profile;
    if (profile?.doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите лечащего врача в профиле.')),
      );
      return;
    }

    final key = _episodeKey(episode);
    final text =
        'Эпизод ухудшения: ${_formatEpisodeDate(episode.startDate)}\n'
        'Причина: ${episode.triggerReason}\n'
        'Изменились показатели: ${episode.changedIndicators.join(', ')}\n\n'
        'Отправлено пациентом из раздела "Эпизоды ухудшения".';

    try {
      await SupabaseService.sendChatMessage(
        receiverId: profile!.doctorId!,
        body: text,
      );
      if (!mounted) return;
      setState(() => _sentEpisodeKeys.add(key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Эпизод отправлен врачу в чат.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отправить эпизод врачу.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final tests = context.watch<TestResultsProvider>();

    final signals = AnalyticsService.generateSignals(
      diary.diaryEntriesSorted,
      tests.results,
    );
    final episodes = AnalyticsService.generateDeteriorationEpisodes(
      diary.diaryEntriesSorted,
      tests.results,
    );

    // Entries for the fatigue-streak detail widget (latest 3, newest first).
    final top3 = diary.diaryEntriesSorted.take(3).toList();
    AnalysisSignal? highSignal;
    for (final signal in signals) {
      if (signal.severity == 'high') {
        highSignal = signal;
        break;
      }
    }

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
                      items: const ['Активные', 'Эпизоды'],
                      active: _tab,
                      onChange: (v) => setState(() => _tab = v),
                    ),
                    const SizedBox(height: 14),

                    if (_tab == 'Эпизоды')
                      _EpisodeHistory(
                        episodes: episodes,
                        sentKeys: _sentEpisodeKeys,
                        onSend: _sendEpisodeToDoctor,
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
                      if (highSignal != null && top3.length >= 3) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NLColors.surface,
                            borderRadius: BorderRadius.all(NLRadius.lg),
                            border: Border.all(color: NLColors.bad, width: 1.5),
                            boxShadow: shadowCard,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NLColors.roseSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Высокий',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: NLColors.bad,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Усталость ≥ 7 три дня подряд',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: NLColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Усталость ≥ 7 в течение 3 записей подряд. '
                                'Следите за состоянием и при необходимости '
                                'обсудите изменения с врачом.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: NLColors.muted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SignalActions(
                                signal: highSignal,
                                sent: _sentSignalKeys.contains(
                                  _signalKey(highSignal),
                                ),
                                onSend: () => _sendToDoctor(highSignal!),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: NLColors.roseSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                            entry.key == top3.length - 1;
                                        final day = e.dateTime.day;
                                        final months = [
                                          'янв',
                                          'фев',
                                          'мар',
                                          'апр',
                                          'май',
                                          'июн',
                                          'июл',
                                          'авг',
                                          'сен',
                                          'окт',
                                          'ноя',
                                          'дек',
                                        ];
                                        final mon =
                                            months[e.dateTime.month - 1];
                                        return _DayValue(
                                          date: '$day $mon',
                                          value: '${e.fatigue}',
                                          highlight: isLast,
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Remaining (non-high) signals.
                      ...signals
                          .where((s) => s.severity != 'high')
                          .map(
                            (s) => _SignalCard(
                              signal: s,
                              level: _level(s.severity),
                              sent: _sentSignalKeys.contains(_signalKey(s)),
                              onSend: () => _sendToDoctor(s),
                            ),
                          ),
                    ],

                    const NLSectionTitle('Правила обнаружения'),
                    NLList(
                      children: [
                        NLListRow(
                          icon: const Icon(
                            Icons.ads_click_rounded,
                            size: 16,
                            color: NLColors.accent,
                          ),
                          iconBg: NLColors.accentSoft,
                          title: 'Порог · 3 дня подряд',
                          sub: 'Усталость ≥ 7',
                          right: const Text(
                            'Вкл',
                            style: TextStyle(
                              fontSize: 14,
                              color: NLColors.muted,
                            ),
                          ),
                        ),
                        NLListRow(
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: NLColors.peach,
                          ),
                          iconBg: NLColors.peachSoft,
                          title: 'Прирост среднего',
                          sub: 'Δ ≥ 20% к прошлой неделе',
                          right: const Text(
                            'Вкл',
                            style: TextStyle(
                              fontSize: 14,
                              color: NLColors.muted,
                            ),
                          ),
                        ),
                        NLListRow(
                          icon: const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: NLColors.rose,
                          ),
                          iconBg: NLColors.roseSoft,
                          title: 'Реакция замедлилась',
                          sub: 'Среднее ≥ +15%',
                          right: const Text(
                            'Вкл',
                            style: TextStyle(
                              fontSize: 14,
                              color: NLColors.muted,
                            ),
                          ),
                        ),
                        NLListRow(
                          icon: const Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: NLColors.mint,
                          ),
                          iconBg: NLColors.mintSoft,
                          title: 'Онемение / чувствительность',
                          sub: 'Порог ≥ 7 или прирост ≥ 20%',
                          right: const Text(
                            'Вкл',
                            style: TextStyle(
                              fontSize: 14,
                              color: NLColors.muted,
                            ),
                          ),
                        ),
                        NLListRow(
                          icon: const Icon(
                            Icons.sports_gymnastics_outlined,
                            size: 16,
                            color: NLColors.sky,
                          ),
                          iconBg: NLColors.skySoft,
                          title: 'Координация, зрение, слабость',
                          sub: 'Порог ≥ 7 или прирост ≥ 20%',
                          right: const Text(
                            'Вкл',
                            style: TextStyle(
                              fontSize: 14,
                              color: NLColors.muted,
                            ),
                          ),
                        ),
                        NLListRow(
                          icon: const Icon(
                            Icons.bolt_outlined,
                            size: 16,
                            color: NLColors.rose,
                          ),
                          iconBg: NLColors.roseSoft,
                          title: 'Стресс / нагрузка',
                          sub: 'Порог ≥ 8 или прирост ≥ 20%',
                          right: const Text(
                            'Вкл',
                            style: TextStyle(
                              fontSize: 14,
                              color: NLColors.muted,
                            ),
                          ),
                        ),
                        NLListRow(
                          icon: const Icon(
                            Icons.back_hand_outlined,
                            size: 16,
                            color: NLColors.accent,
                          ),
                          iconBg: NLColors.accentSoft,
                          title: 'Таппинг по рукам',
                          sub: 'Снижение ≥ 15% к прошлой неделе',
                          last: true,
                          right: const Text(
                            'Вкл',
                            style: TextStyle(
                              fontSize: 14,
                              color: NLColors.muted,
                            ),
                          ),
                        ),
                      ],
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

class _SignalCard extends StatelessWidget {
  final AnalysisSignal signal;
  final NLSignalLevel level;
  final bool sent;
  final VoidCallback onSend;

  const _SignalCard({
    required this.signal,
    required this.level,
    required this.sent,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bg = level == NLSignalLevel.bad
        ? NLColors.roseSoft
        : level == NLSignalLevel.warn
        ? NLColors.peachSoft
        : NLColors.skySoft;
    final dot = level == NLSignalLevel.bad
        ? NLColors.bad
        : level == NLSignalLevel.warn
        ? NLColors.warn
        : NLColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.all(NLRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 12),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NLColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      signal.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: NLColors.ink2,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SignalActions(signal: signal, sent: sent, onSend: onSend),
        ],
      ),
    );
  }
}

class _SignalActions extends StatelessWidget {
  final AnalysisSignal signal;
  final bool sent;
  final VoidCallback onSend;

  const _SignalActions({
    required this.signal,
    required this.sent,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            signal.severity == 'high'
                ? 'Высокий приоритет'
                : 'Можно отправить врачу вручную',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: signal.severity == 'high' ? NLColors.bad : NLColors.muted,
            ),
          ),
        ),
        GestureDetector(
          onTap: sent ? null : onSend,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sent ? NLColors.mintSoft : NLColors.accent,
              borderRadius: BorderRadius.all(NLRadius.pill),
            ),
            child: Text(
              sent ? 'Отправлено' : 'Врачу',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sent ? NLColors.good : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EpisodeHistory extends StatelessWidget {
  final List<DeteriorationEpisode> episodes;
  final Set<String> sentKeys;
  final ValueChanged<DeteriorationEpisode> onSend;

  const _EpisodeHistory({
    required this.episodes,
    required this.sentKeys,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return const _EmptyState(
        icon: Icons.timeline_outlined,
        message: 'Эпизодов ухудшения нет',
        sub: 'История появится из отметок дневника и правил анализа.',
      );
    }

    return Column(
      children: [
        _EpisodeSummary(episodes: episodes),
        const SizedBox(height: 10),
        ...episodes.map((episode) {
          final sent = episode.sentToDoctor || sentKeys.contains(episode.id);
          return _EpisodeCard(
            episode: episode,
            sent: sent,
            onSend: () => onSend(episode),
          );
        }),
      ],
    );
  }
}

class _EpisodeSummary extends StatelessWidget {
  final List<DeteriorationEpisode> episodes;

  const _EpisodeSummary({required this.episodes});

  @override
  Widget build(BuildContext context) {
    final latest = episodes.first.startDate;
    final highCount = episodes.where((e) => e.severity == 'high').length;

    return NLCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: NLColors.roseSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 22,
              color: NLColors.bad,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${episodes.length} ${_episodeWord(episodes.length)} в истории',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: NLColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Последний: ${_formatEpisodeDate(latest)} · высокий приоритет: $highCount',
                  style: const TextStyle(fontSize: 12, color: NLColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final DeteriorationEpisode episode;
  final bool sent;
  final VoidCallback onSend;

  const _EpisodeCard({
    required this.episode,
    required this.sent,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = episode.severity == 'high';
    final accent = isHigh ? NLColors.bad : NLColors.warn;
    final soft = isHigh ? NLColors.roseSoft : NLColors.peachSoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NLColors.surface,
        borderRadius: BorderRadius.all(NLRadius.lg),
        border: Border.all(color: soft),
        boxShadow: shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.all(NLRadius.pill),
                ),
                child: Text(
                  isHigh ? 'Высокий' : 'Наблюдать',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatEpisodeDate(episode.startDate),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NLColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Эпизод ухудшения',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: NLColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            episode.triggerReason,
            style: const TextStyle(
              fontSize: 13,
              color: NLColors.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: episode.changedIndicators
                .map((indicator) => _EpisodeIndicator(label: indicator))
                .toList(),
          ),
          const SizedBox(height: 14),
          _EpisodeMetaRow(
            icon: Icons.medical_services_outlined,
            title: 'Отправлено врачу',
            value: sent ? 'Да' : 'Нет',
            valueColor: sent ? NLColors.good : NLColors.muted,
          ),
          const SizedBox(height: 8),
          _EpisodeMetaRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Комментарий врача',
            value: episode.doctorComment ?? 'Комментария пока нет',
            valueColor: NLColors.muted,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: sent ? null : onSend,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sent ? NLColors.mintSoft : NLColors.accent,
                  borderRadius: BorderRadius.all(NLRadius.pill),
                ),
                child: Text(
                  sent ? 'Отправлено' : 'Отправить врачу',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sent ? NLColors.good : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeIndicator extends StatelessWidget {
  final String label;

  const _EpisodeIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NLColors.surface2,
        borderRadius: BorderRadius.all(NLRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: NLColors.ink2,
        ),
      ),
    );
  }
}

class _EpisodeMetaRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const _EpisodeMetaRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: NLColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: NLColors.muted),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return NLCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: NLColors.muted),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: NLColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: NLColors.muted),
          ),
        ],
      ),
    );
  }
}

String _formatEpisodeDate(DateTime dt) {
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String _episodeWord(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'эпизод';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'эпизода';
  }
  return 'эпизодов';
}

class _DayValue extends StatelessWidget {
  final String date;
  final String value;
  final bool highlight;
  const _DayValue({
    required this.date,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(date, style: const TextStyle(fontSize: 12, color: NLColors.ink2)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: highlight ? NLColors.bad : NLColors.ink,
          ),
        ),
      ],
    );
  }
}
