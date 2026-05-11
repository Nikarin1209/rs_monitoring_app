import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../models/user_profile.dart';
import '../state/profile_provider.dart';
import '../state/diary_provider.dart';
import '../state/test_results_provider.dart';
import '../state/settings_provider.dart';
import 'export_screen.dart';
import 'reminders_screen.dart';
import 'splash_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(bottom: false, child: const SettingsBody()),
    );
  }
}

class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  // ── Observation date formatter ──────────────────────────────────────────
  static String _obsDate(DateTime dt) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return 'Наблюдение с ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Edit personal data dialog ───────────────────────────────────────────
  static Future<void> _showEditProfileDialog(
      BuildContext context, UserProfile profile) async {
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    DateTime selectedDate = profile.observationStartDate;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: NLColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Личные данные',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NLColors.ink)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Имя',
                    style: TextStyle(fontSize: 12, color: NLColors.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: NLColors.ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: NLColors.surface2,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Email',
                    style: TextStyle(fontSize: 12, color: NLColors.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: NLColors.ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: NLColors.surface2,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Начало наблюдения',
                    style: TextStyle(fontSize: 12, color: NLColors.muted)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: NLColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          '${selectedDate.day}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                          style: const TextStyle(
                              fontSize: 16, color: NLColors.ink),
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: NLColors.muted),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена',
                  style: TextStyle(color: NLColors.muted)),
            ),
            TextButton(
              onPressed: () async {
                final newProfile = profile.copyWith(
                  name: nameCtrl.text.trim().isEmpty
                      ? profile.name
                      : nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  observationStartDate: selectedDate,
                );
                await context
                    .read<ProfileProvider>()
                    .saveProfile(newProfile);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Сохранить',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: NLColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit baseline dialog ────────────────────────────────────────────────
  static Future<void> _showEditBaselineDialog(
      BuildContext context, UserProfile profile) async {
    int fatigue = profile.baselineFatigue;
    int pain = profile.baselinePain;
    double sleep = profile.baselineSleep;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: NLColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Базовый уровень',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NLColors.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BaselineStepper(
                label: 'Усталость',
                value: fatigue,
                min: 0,
                max: 10,
                onChanged: (v) => setDialogState(() => fatigue = v),
              ),
              const SizedBox(height: 16),
              _BaselineStepper(
                label: 'Боль',
                value: pain,
                min: 0,
                max: 10,
                onChanged: (v) => setDialogState(() => pain = v),
              ),
              const SizedBox(height: 16),
              _BaselineSlider(
                label: 'Сон',
                value: sleep,
                min: 0,
                max: 12,
                onChanged: (v) =>
                    setDialogState(() => sleep = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена',
                  style: TextStyle(color: NLColors.muted)),
            ),
            TextButton(
              onPressed: () async {
                final newProfile = profile.copyWith(
                  baselineFatigue: fatigue,
                  baselinePain: pain,
                  baselineSleep: sleep,
                );
                await context
                    .read<ProfileProvider>()
                    .saveProfile(newProfile);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Сохранить',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: NLColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete all data dialog ──────────────────────────────────────────────
  static Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NLColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить все данные?',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NLColors.ink)),
        content: const Text(
          'Будут удалены профиль, записи дневника, результаты тестов и настройки. '
          'Это действие нельзя отменить.',
          style: TextStyle(fontSize: 14, color: NLColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена',
                style: TextStyle(color: NLColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: NLColors.bad)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await Future.wait([
      context.read<ProfileProvider>().deleteProfile(),
      context.read<DiaryProvider>().deleteAll(),
      context.read<TestResultsProvider>().deleteAll(),
      context.read<SettingsProvider>().resetToDefaults(),
    ]);

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final sp = context.watch<SettingsProvider>();
    final reminderCount = sp.activeReminderCount;

    final avatarLetter = profile != null && profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';
    final name = profile?.name ?? '—';
    final obsText =
        profile != null ? _obsDate(profile.observationStartDate) : '';
    final baselineSub = profile != null
        ? 'Усталость ${profile.baselineFatigue} · Боль ${profile.baselinePain} · Сон ${profile.baselineSleep.toStringAsFixed(1)}ч'
        : '—';
    final faceIdOn = profile?.faceIdEnabled ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NLHeader(greeting: 'Профиль', title: 'Настройки'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card
                GestureDetector(
                  onTap: profile != null
                      ? () => _showEditProfileDialog(context, profile)
                      : null,
                  child: NLCard(
                    child: Row(children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [NLColors.peach, NLColors.rose],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(avatarLetter,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: NLColors.ink)),
                            const SizedBox(height: 2),
                            Text(obsText,
                                style: const TextStyle(
                                    fontSize: 12, color: NLColors.muted)),
                          ])),
                      const Icon(Icons.chevron_right_rounded,
                          color: NLColors.muted, size: 20),
                    ]),
                  ),
                ),

                const NLSectionTitle('Профиль'),
                NLList(children: [
                  GestureDetector(
                    onTap: profile != null
                        ? () => _showEditProfileDialog(context, profile)
                        : null,
                    child: const NLListRow(
                      icon: Icon(Icons.person_outline_rounded,
                          size: 16, color: NLColors.ink),
                      title: 'Личные данные',
                    ),
                  ),
                  GestureDetector(
                    onTap: profile != null
                        ? () => _showEditBaselineDialog(context, profile)
                        : null,
                    child: NLListRow(
                      icon: const Icon(Icons.ads_click_rounded,
                          size: 16, color: NLColors.ink),
                      title: 'Базовый уровень',
                      sub: baselineSub,
                    ),
                  ),
                  const NLListRow(
                    icon: Icon(Icons.tune_rounded,
                        size: 16, color: NLColors.ink),
                    title: 'Шкалы и единицы',
                    last: true,
                    right: Text('0–10 ›',
                        style:
                            TextStyle(fontSize: 14, color: NLColors.muted)),
                  ),
                ]),

                const NLSectionTitle('Приватность'),
                NLList(children: [
                  const NLListRow(
                    icon: Icon(Icons.lock_outline_rounded,
                        size: 16, color: NLColors.accent),
                    iconBg: NLColors.accentSoft,
                    title: 'Защита приложения',
                    sub: 'Face ID · PIN',
                  ),
                  NLListRow(
                    icon: const Icon(Icons.face_retouching_natural,
                        size: 16, color: NLColors.ink),
                    title: 'Face ID при входе',
                    right: GestureDetector(
                      onTap: profile != null
                          ? () async {
                              await context
                                  .read<ProfileProvider>()
                                  .saveProfile(profile.copyWith(
                                      faceIdEnabled: !faceIdOn));
                            }
                          : null,
                      child: NLToggle(on: faceIdOn),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ExportScreen())),
                    child: NLListRow(
                      icon: const Icon(Icons.download_outlined,
                          size: 16, color: NLColors.ink),
                      title: 'Экспорт данных',
                      right: const Icon(Icons.chevron_right_rounded,
                          color: NLColors.muted, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(context),
                    child: const NLListRow(
                      title: 'Удалить все данные',
                      last: true,
                      right: Icon(Icons.chevron_right_rounded,
                          color: NLColors.bad, size: 20),
                    ),
                  ),
                ]),

                const NLSectionTitle('Приложение'),
                NLList(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RemindersScreen())),
                    child: NLListRow(
                      icon: const Icon(Icons.notifications_outlined,
                          size: 16, color: NLColors.ink),
                      title: 'Напоминания',
                      right: Text('$reminderCount ›',
                          style: const TextStyle(
                              fontSize: 14, color: NLColors.muted)),
                    ),
                  ),
                  const NLListRow(
                    title: 'Язык',
                    right: Text('Русский ›',
                        style:
                            TextStyle(fontSize: 14, color: NLColors.muted)),
                  ),
                  const NLListRow(
                    title: 'Тема',
                    last: true,
                    right: Text('Системная ›',
                        style:
                            TextStyle(fontSize: 14, color: NLColors.muted)),
                  ),
                ]),

                const SizedBox(height: 20),
                const Center(
                  child: Text('NeuroLife · 1.0.0',
                      style:
                          TextStyle(fontSize: 12, color: NLColors.muted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Baseline stepper ──────────────────────────────────────────────────────

class _BaselineStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _BaselineStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: NLColors.ink))),
      GestureDetector(
        onTap: value > min ? () => onChanged(value - 1) : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              color: NLColors.surface2, shape: BoxShape.circle),
          child: Icon(Icons.remove,
              size: 18,
              color: value > min ? NLColors.ink : NLColors.muted),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('$value',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NLColors.ink)),
      ),
      GestureDetector(
        onTap: value < max ? () => onChanged(value + 1) : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              color: NLColors.surface2, shape: BoxShape.circle),
          child: Icon(Icons.add,
              size: 18,
              color: value < max ? NLColors.ink : NLColors.muted),
        ),
      ),
    ]);
  }
}

// ── Baseline sleep slider ─────────────────────────────────────────────────

class _BaselineSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _BaselineSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
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
        Text('${value.toStringAsFixed(1)} ч',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NLColors.accent)),
      ]),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: 24,
        activeColor: NLColors.accent,
        inactiveColor: NLColors.surface2,
        onChanged: (v) => onChanged((v * 2).round() / 2),
      ),
    ]);
  }
}
