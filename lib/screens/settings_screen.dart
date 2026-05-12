import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../state/profile_provider.dart';
import '../state/diary_provider.dart';
import '../state/test_results_provider.dart';
import '../state/settings_provider.dart';
import 'export_screen.dart';
import 'reminders_screen.dart';
import 'splash_screen.dart';

Future<void> performLogout(BuildContext context) async {
  context.read<DiaryProvider>().clear();
  context.read<TestResultsProvider>().clear();
  context.read<SettingsProvider>().clear();
  await context.read<ProfileProvider>().signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SplashScreen()),
    (_) => false,
  );
}

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
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return 'Наблюдение с ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _shortDate(DateTime? dt) {
    if (dt == null) return 'Не указано';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  static String _sexLabel(String value) {
    switch (value) {
      case 'female':
        return 'Женский';
      case 'male':
        return 'Мужской';
      case 'other':
        return 'Другое';
      default:
        return 'Пол не указан';
    }
  }

  static String _msTypeLabel(String value) {
    switch (value) {
      case 'rrms':
        return 'Ремиттирующий РС';
      case 'spms':
        return 'Вторично-прогрессирующий РС';
      case 'ppms':
        return 'Первично-прогрессирующий РС';
      case 'cis':
        return 'КИС';
      case 'unknown':
        return 'Тип РС не уточнён';
      default:
        return 'Тип РС не указан';
    }
  }

  static int? _age(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static String _personalDataSub(UserProfile profile) {
    final age = _age(profile.birthDate);
    final parts = [
      if (age != null) '$age лет',
      _sexLabel(profile.sex),
      _msTypeLabel(profile.msType),
    ];
    return parts.join(' · ');
  }

  static String _profileSaveError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('could not find') ||
          message.contains('schema cache') ||
          message.contains('column')) {
        return 'База данных ещё не обновлена. Запустите миграцию для новых полей профиля.';
      }
      if (message.contains('row-level security') || message.contains('rls')) {
        return 'Supabase отклонил сохранение профиля из-за RLS. Войдите заново.';
      }
      return 'Не удалось сохранить профиль: ${error.message}';
    }
    return 'Не удалось сохранить профиль. Попробуйте ещё раз.';
  }

  static void _showProfileSaveError(BuildContext context, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_profileSaveError(error))));
  }

  // ── Edit personal data dialog ───────────────────────────────────────────
  static Future<void> _showEditProfileDialog(
    BuildContext context,
    UserProfile profile,
  ) async {
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final therapyCtrl = TextEditingController(text: profile.currentTherapy);
    final clinicCtrl = TextEditingController(text: profile.clinicName);
    final emergencyNameCtrl = TextEditingController(
      text: profile.emergencyContactName,
    );
    final emergencyPhoneCtrl = TextEditingController(
      text: profile.emergencyContactPhone,
    );

    DateTime selectedObservationDate = profile.observationStartDate;
    DateTime? selectedBirthDate = profile.birthDate;
    DateTime? selectedDiagnosisDate = profile.diagnosisDate;
    String selectedSex = profile.sex;
    String selectedMsType = profile.msType;
    String selectedDoctorId = profile.doctorId ?? '';
    List<DoctorListItem> doctors = const [];
    try {
      doctors = await SupabaseService.getDoctors();
    } catch (_) {
      doctors = const [];
    }
    if (!context.mounted) return;
    if (selectedDoctorId.isNotEmpty &&
        !doctors.any((doctor) => doctor.id == selectedDoctorId)) {
      selectedDoctorId = '';
    }
    const sexItems = {
      '': 'Не указан',
      'female': 'Женский',
      'male': 'Мужской',
      'other': 'Другое',
    };
    const msTypeItems = {
      '': 'Не указан',
      'rrms': 'Ремиттирующий',
      'spms': 'Вторично-прогрессирующий',
      'ppms': 'Первично-прогрессирующий',
      'cis': 'Клинически изолированный синдром',
      'unknown': 'Не знаю',
    };
    if (!sexItems.containsKey(selectedSex)) selectedSex = '';
    if (!msTypeItems.containsKey(selectedMsType)) selectedMsType = '';

    Future<DateTime?> pickDate(
      BuildContext ctx, {
      required DateTime? current,
      required DateTime firstDate,
      required DateTime lastDate,
    }) => showDatePicker(
      context: ctx,
      initialDate: current ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: NLColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Личные данные',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NLColors.ink,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileSectionLabel('Основное'),
                  _ProfileTextField(label: 'Имя', controller: nameCtrl),
                  const SizedBox(height: 14),
                  _ProfileTextField(
                    label: 'Email',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _ProfileDropdown(
                    label: 'Пол',
                    value: selectedSex,
                    items: sexItems,
                    onChanged: (v) =>
                        setDialogState(() => selectedSex = v ?? ''),
                  ),
                  const SizedBox(height: 14),
                  _ProfileDateTile(
                    label: 'Дата рождения',
                    value: _shortDate(selectedBirthDate),
                    onTap: () async {
                      final picked = await pickDate(
                        ctx,
                        current: selectedBirthDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedBirthDate = picked);
                      }
                    },
                    onClear: selectedBirthDate == null
                        ? null
                        : () => setDialogState(() => selectedBirthDate = null),
                  ),
                  const SizedBox(height: 14),
                  _ProfileDateTile(
                    label: 'Начало наблюдения',
                    value: _shortDate(selectedObservationDate),
                    onTap: () async {
                      final picked = await pickDate(
                        ctx,
                        current: selectedObservationDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedObservationDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const _ProfileSectionLabel('Медицинские данные'),
                  _ProfileDropdown(
                    label: 'Тип РС',
                    value: selectedMsType,
                    items: msTypeItems,
                    onChanged: (v) =>
                        setDialogState(() => selectedMsType = v ?? ''),
                  ),
                  const SizedBox(height: 14),
                  _ProfileDateTile(
                    label: 'Дата диагноза',
                    value: _shortDate(selectedDiagnosisDate),
                    onTap: () async {
                      final picked = await pickDate(
                        ctx,
                        current: selectedDiagnosisDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDiagnosisDate = picked);
                      }
                    },
                    onClear: selectedDiagnosisDate == null
                        ? null
                        : () => setDialogState(
                            () => selectedDiagnosisDate = null,
                          ),
                  ),
                  const SizedBox(height: 14),
                  _ProfileTextField(
                    label: 'Текущая терапия',
                    controller: therapyCtrl,
                    hintText: 'Например, ПИТРС или препарат',
                  ),
                  const SizedBox(height: 14),
                  _ProfileDoctorDropdown(
                    label: 'Лечащий врач',
                    value: selectedDoctorId,
                    doctors: doctors,
                    onChanged: (v) =>
                        setDialogState(() => selectedDoctorId = v ?? ''),
                  ),
                  const SizedBox(height: 14),
                  _ProfileTextField(label: 'Клиника', controller: clinicCtrl),
                  const SizedBox(height: 20),
                  const _ProfileSectionLabel('Контакты'),
                  _ProfileTextField(
                    label: 'Телефон',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _ProfileTextField(
                    label: 'Экстренный контакт',
                    controller: emergencyNameCtrl,
                  ),
                  const SizedBox(height: 14),
                  _ProfileTextField(
                    label: 'Телефон экстренного контакта',
                    controller: emergencyPhoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Отмена',
                  style: TextStyle(color: NLColors.muted),
                ),
              ),
              TextButton(
                onPressed: () async {
                  DoctorListItem? selectedDoctor;
                  for (final doctor in doctors) {
                    if (doctor.id == selectedDoctorId) {
                      selectedDoctor = doctor;
                      break;
                    }
                  }
                  final newProfile = profile.copyWith(
                    name: nameCtrl.text.trim().isEmpty
                        ? profile.name
                        : nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    observationStartDate: selectedObservationDate,
                    birthDate: selectedBirthDate,
                    sex: selectedSex,
                    phone: phoneCtrl.text.trim(),
                    msType: selectedMsType,
                    diagnosisDate: selectedDiagnosisDate,
                    currentTherapy: therapyCtrl.text.trim(),
                    doctorId: selectedDoctorId.isEmpty
                        ? null
                        : selectedDoctorId,
                    doctorName: selectedDoctor?.name ?? '',
                    clinicName: clinicCtrl.text.trim(),
                    emergencyContactName: emergencyNameCtrl.text.trim(),
                    emergencyContactPhone: emergencyPhoneCtrl.text.trim(),
                  );
                  try {
                    await context.read<ProfileProvider>().saveProfile(
                      newProfile,
                      throwOnError: true,
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  } catch (e) {
                    if (context.mounted) _showProfileSaveError(context, e);
                  }
                },
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: NLColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      therapyCtrl.dispose();
      clinicCtrl.dispose();
      emergencyNameCtrl.dispose();
      emergencyPhoneCtrl.dispose();
    }
  }

  // ── Edit baseline dialog ────────────────────────────────────────────────
  static Future<void> _showEditBaselineDialog(
    BuildContext context,
    UserProfile profile,
  ) async {
    int fatigue = profile.baselineFatigue;
    int pain = profile.baselinePain;
    double sleep = profile.baselineSleep;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: NLColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Базовый уровень',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NLColors.ink,
            ),
          ),
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
                onChanged: (v) => setDialogState(() => sleep = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(color: NLColors.muted),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newProfile = profile.copyWith(
                  baselineFatigue: fatigue,
                  baselinePain: pain,
                  baselineSleep: sleep,
                );
                try {
                  await context.read<ProfileProvider>().saveProfile(
                    newProfile,
                    throwOnError: true,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (context.mounted) _showProfileSaveError(context, e);
                }
              },
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: NLColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ──────────────────────────────────────────────────────
  static Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NLColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Выйти из аккаунта?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: NLColors.ink,
          ),
        ),
        content: const Text(
          'Ваши данные останутся в облаке. При следующем входе всё восстановится.',
          style: TextStyle(fontSize: 14, color: NLColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: NLColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Выйти',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: NLColors.bad,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await performLogout(context);
  }

  // ── Delete all data dialog ──────────────────────────────────────────────
  static Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NLColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Удалить все данные?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: NLColors.ink,
          ),
        ),
        content: const Text(
          'Будут удалены профиль, записи дневника, результаты тестов и настройки. '
          'Это действие нельзя отменить.',
          style: TextStyle(fontSize: 14, color: NLColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: NLColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: NLColors.bad,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final diary = context.read<DiaryProvider>();
    final tests = context.read<TestResultsProvider>();
    final profile = context.read<ProfileProvider>();
    final settings = context.read<SettingsProvider>();

    await diary.deleteAll();
    await tests.deleteAll();
    await profile.deleteProfile();
    diary.clear();
    tests.clear();
    settings.clear();
    await profile.signOut();

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
    final obsText = profile != null
        ? _obsDate(profile.observationStartDate)
        : '';
    final baselineSub = profile != null
        ? 'Усталость ${profile.baselineFatigue} · Боль ${profile.baselinePain} · Сон ${profile.baselineSleep.toStringAsFixed(1)}ч'
        : '—';
    final personalDataSub = profile != null ? _personalDataSub(profile) : '—';
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
                    child: Row(
                      children: [
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
                          child: Text(
                            avatarLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: NLColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                obsText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NLColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: NLColors.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const NLSectionTitle('Профиль'),
                NLList(
                  children: [
                    GestureDetector(
                      onTap: profile != null
                          ? () => _showEditProfileDialog(context, profile)
                          : null,
                      child: NLListRow(
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: NLColors.ink,
                        ),
                        title: 'Личные данные',
                        sub: personalDataSub,
                      ),
                    ),
                    GestureDetector(
                      onTap: profile != null
                          ? () => _showEditBaselineDialog(context, profile)
                          : null,
                      child: NLListRow(
                        icon: const Icon(
                          Icons.ads_click_rounded,
                          size: 16,
                          color: NLColors.ink,
                        ),
                        title: 'Базовый уровень',
                        sub: baselineSub,
                      ),
                    ),
                    const NLListRow(
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: NLColors.ink,
                      ),
                      title: 'Шкалы и единицы',
                      last: true,
                      right: Text(
                        '0–10 ›',
                        style: TextStyle(fontSize: 14, color: NLColors.muted),
                      ),
                    ),
                  ],
                ),

                const NLSectionTitle('Приватность'),
                NLList(
                  children: [
                    const NLListRow(
                      icon: Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: NLColors.accent,
                      ),
                      iconBg: NLColors.accentSoft,
                      title: 'Защита приложения',
                      sub: 'Face ID · PIN',
                    ),
                    NLListRow(
                      icon: const Icon(
                        Icons.face_retouching_natural,
                        size: 16,
                        color: NLColors.ink,
                      ),
                      title: 'Face ID при входе',
                      right: GestureDetector(
                        onTap: profile != null
                            ? () async {
                                try {
                                  await context
                                      .read<ProfileProvider>()
                                      .saveProfile(
                                        profile.copyWith(
                                          faceIdEnabled: !faceIdOn,
                                        ),
                                        throwOnError: true,
                                      );
                                } catch (e) {
                                  if (context.mounted) {
                                    _showProfileSaveError(context, e);
                                  }
                                }
                              }
                            : null,
                        child: NLToggle(on: faceIdOn),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExportScreen()),
                      ),
                      child: NLListRow(
                        icon: const Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: NLColors.ink,
                        ),
                        title: 'Экспорт данных',
                        right: const Icon(
                          Icons.chevron_right_rounded,
                          color: NLColors.muted,
                          size: 20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showDeleteDialog(context),
                      child: const NLListRow(
                        title: 'Удалить все данные',
                        last: true,
                        right: Icon(
                          Icons.chevron_right_rounded,
                          color: NLColors.bad,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const NLSectionTitle('Приложение'),
                NLList(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RemindersScreen(),
                        ),
                      ),
                      child: NLListRow(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 16,
                          color: NLColors.ink,
                        ),
                        title: 'Напоминания',
                        right: Text(
                          '$reminderCount ›',
                          style: const TextStyle(
                            fontSize: 14,
                            color: NLColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const NLListRow(
                      title: 'Язык',
                      right: Text(
                        'Русский ›',
                        style: TextStyle(fontSize: 14, color: NLColors.muted),
                      ),
                    ),
                    const NLListRow(
                      title: 'Тема',
                      last: true,
                      right: Text(
                        'Системная ›',
                        style: TextStyle(fontSize: 14, color: NLColors.muted),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                NLList(
                  children: [
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context),
                      child: const NLListRow(
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: NLColors.bad,
                        ),
                        title: 'Выйти из аккаунта',
                        last: true,
                        right: Icon(
                          Icons.chevron_right_rounded,
                          color: NLColors.bad,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'NeuroLife · 1.0.0',
                    style: TextStyle(fontSize: 12, color: NLColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  final String text;

  const _ProfileSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: NLColors.ink,
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hintText;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: NLColors.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: NLColors.ink),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: NLColors.muted),
            filled: true,
            fillColor: NLColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _ProfileDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: NLColors.muted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: NLColors.muted,
          ),
          dropdownColor: NLColors.surface,
          style: const TextStyle(color: NLColors.ink, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: NLColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: items.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ProfileDoctorDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DoctorListItem> doctors;
  final ValueChanged<String?> onChanged;

  const _ProfileDoctorDropdown({
    required this.label,
    required this.value,
    required this.doctors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const DropdownMenuItem<String>(value: '', child: Text('Не выбран')),
      ...doctors.map(
        (doctor) => DropdownMenuItem<String>(
          value: doctor.id,
          child: Text(doctor.label, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: NLColors.muted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: NLColors.muted,
          ),
          dropdownColor: NLColors.surface,
          style: const TextStyle(color: NLColors.ink, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: NLColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            helperText: doctors.isEmpty
                ? 'Здесь появятся зарегистрированные врачи'
                : null,
            helperStyle: const TextStyle(color: NLColors.muted, fontSize: 12),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ProfileDateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _ProfileDateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: NLColors.muted),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: NLColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: value == 'Не указано'
                          ? NLColors.muted
                          : NLColors.ink,
                    ),
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.close, size: 16, color: NLColors.muted),
                    ),
                  ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: NLColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NLColors.ink,
            ),
          ),
        ),
        GestureDetector(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: NLColors.surface2,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove,
              size: 18,
              color: value > min ? NLColors.ink : NLColors.muted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NLColors.ink,
            ),
          ),
        ),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: NLColors.surface2,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: value < max ? NLColors.ink : NLColors.muted,
            ),
          ),
        ),
      ],
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: NLColors.ink,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} ч',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NLColors.accent,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 24,
          activeColor: NLColors.accent,
          inactiveColor: NLColors.surface2,
          onChanged: (v) => onChanged((v * 2).round() / 2),
        ),
      ],
    );
  }
}
