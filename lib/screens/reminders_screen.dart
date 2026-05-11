import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/settings_provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: const _RemindersBody(),
      ),
    );
  }
}

class _RemindersBody extends StatelessWidget {
  const _RemindersBody();

  // ── Time helpers ──────────────────────────────────────────────────────

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _fmtTime(String hhmm) {
    final t = _parseTime(hhmm);
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _timeToHhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(
    BuildContext context,
    String currentHhmm,
    Future<void> Function(String) onSave,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(currentHhmm),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: NLColors.accent,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      await onSave(_timeToHhmm(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final s = sp.settings;
    final activeCount = sp.activeReminderCount;

    final notifOn = s.notificationsEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NLTopBar(
            leading: NLBackBtn(),
            title: 'Напоминания',
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master notifications toggle card
                NLCard(
                  color: notifOn
                      ? NLColors.accentSoft
                      : NLColors.surface2,
                  child: Row(children: [
                    Icon(
                      notifOn
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                      color: notifOn
                          ? NLColors.accent
                          : NLColors.muted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(
                            notifOn
                                ? 'Уведомления включены'
                                : 'Уведомления выключены',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: NLColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeCount == 0
                                ? 'Нет активных напоминаний'
                                : '$activeCount активных напоминания',
                            style: const TextStyle(
                                fontSize: 12, color: NLColors.muted),
                          ),
                        ])),
                    GestureDetector(
                      onTap: () async {
                        await context
                            .read<SettingsProvider>()
                            .setNotificationsEnabled(!notifOn);
                      },
                      child: NLToggle(on: notifOn),
                    ),
                  ]),
                ),

                const NLSectionTitle('Расписание'),
                NLList(children: [
                  // Diary reminder
                  _ReminderRow(
                    icon: const Icon(Icons.book_outlined,
                        size: 16, color: NLColors.accent),
                    iconBg: NLColors.accentSoft,
                    title: 'Запись в дневник',
                    sub: 'Каждый день · ${_fmtTime(s.diaryReminderTime)}',
                    enabled: s.diaryReminderEnabled,
                    onToggle: () async {
                      await context
                          .read<SettingsProvider>()
                          .setDiaryReminder(
                              enabled: !s.diaryReminderEnabled);
                    },
                    onTimeTap: () => _pickTime(
                      context,
                      s.diaryReminderTime,
                      (t) async {
                        await context
                            .read<SettingsProvider>()
                            .setDiaryReminder(time: t);
                      },
                    ),
                  ),
                  // Tapping reminder
                  _ReminderRow(
                    icon: const Icon(Icons.ads_click_rounded,
                        size: 16, color: NLColors.peach),
                    iconBg: NLColors.peachSoft,
                    title: 'Таппинг-тест',
                    sub: 'Пн, Ср, Пт · ${_fmtTime(s.tappingReminderTime)}',
                    enabled: s.tappingReminderEnabled,
                    onToggle: () async {
                      await context
                          .read<SettingsProvider>()
                          .setTappingReminder(
                              enabled: !s.tappingReminderEnabled);
                    },
                    onTimeTap: () => _pickTime(
                      context,
                      s.tappingReminderTime,
                      (t) async {
                        await context
                            .read<SettingsProvider>()
                            .setTappingReminder(time: t);
                      },
                    ),
                  ),
                  // Reaction reminder
                  _ReminderRow(
                    icon: const Icon(Icons.bolt_rounded,
                        size: 16, color: NLColors.rose),
                    iconBg: NLColors.roseSoft,
                    title: 'Тест реакции',
                    sub: 'Вс · ${_fmtTime(s.reactionReminderTime)}',
                    enabled: s.reactionReminderEnabled,
                    onToggle: () async {
                      await context
                          .read<SettingsProvider>()
                          .setReactionReminder(
                              enabled: !s.reactionReminderEnabled);
                    },
                    onTimeTap: () => _pickTime(
                      context,
                      s.reactionReminderTime,
                      (t) async {
                        await context
                            .read<SettingsProvider>()
                            .setReactionReminder(time: t);
                      },
                    ),
                    last: true,
                  ),
                ]),

                // Note: actual push notification scheduling requires
                // flutter_local_notifications. Times and toggles are
                // persisted locally via SettingsProvider.
                const SizedBox(height: 10),
                const Text(
                  'Настройки сохраняются локально. '
                  'Для работы системных уведомлений потребуется разрешение.',
                  style: TextStyle(
                      fontSize: 12, color: NLColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminder row ──────────────────────────────────────────────────────────

class _ReminderRow extends StatelessWidget {
  final Widget icon;
  final Color iconBg;
  final String title;
  final String sub;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onTimeTap;
  final bool last;

  const _ReminderRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.sub,
    required this.enabled,
    required this.onToggle,
    required this.onTimeTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: NLColors.line2, width: 1)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTimeTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: NLColors.ink)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: NLColors.muted)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined,
                      size: 12, color: NLColors.muted),
                ]),
              ],
            ),
          ),
        ),
        GestureDetector(onTap: onToggle, child: NLToggle(on: enabled)),
      ]),
    );
  }
}
