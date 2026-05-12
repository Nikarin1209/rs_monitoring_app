import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../state/profile_provider.dart';
import '../widgets/nl_widgets.dart';
import 'doctor_home_screen.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _doctorSpecialtyCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late final TapGestureRecognizer _policyLinkRecognizer;

  DateTime _observationDate = DateTime.now();
  String _selectedRole = UserRole.patient;
  bool _policyAccepted = false;
  bool _policyError = false;
  bool _loading = false;
  String? _authError;
  String? _statusMessage;

  static const _months = [
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

  @override
  void initState() {
    super.initState();
    _policyLinkRecognizer = TapGestureRecognizer()..onTap = _showPolicyDialog;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _doctorSpecialtyCtrl.dispose();
    _clinicCtrl.dispose();
    _phoneCtrl.dispose();
    _policyLinkRecognizer.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _observationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _observationDate = picked);
    }
  }

  void _showPolicyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Политика хранения данных'),
        content: const Text(
          'Данные приложения NeuroLife хранятся в защищённом облачном хранилище '
          'и используются для ведения дневника самочувствия, результатов мини-тестов, '
          'аналитики и формирования отчётов. Приложение не заменяет консультацию врача '
          'и не выполняет медицинскую диагностику.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите имя';
    if (!RegExp(r'^[А-ЯA-ZЁ][а-яА-Яa-zA-ZёЁ\s\-]+$').hasMatch(v.trim())) {
      return 'Имя должно начинаться с большой буквы и содержать только буквы';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите email';
    if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
      return 'Введите корректный email, например name@mail.com';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Введите пароль';
    if (v.length < 8) return 'Пароль должен содержать минимум 8 символов';
    if (!RegExp(r'[a-zа-яё]').hasMatch(v)) {
      return 'Добавьте хотя бы одну строчную букву';
    }
    if (!RegExp(r'[A-ZА-ЯЁ]').hasMatch(v)) {
      return 'Добавьте хотя бы одну заглавную букву';
    }
    if (!RegExp(r'\d').hasMatch(v)) return 'Добавьте хотя бы одну цифру';
    return null;
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user already exists')) {
      return 'Пользователь с таким email уже зарегистрирован';
    }
    if ((msg.contains('signup') && msg.contains('disabled')) ||
        msg.contains('signups not allowed')) {
      return 'Регистрация отключена в настройках Supabase Auth';
    }
    if (msg.contains('email provider') && msg.contains('disabled')) {
      return 'Email-регистрация отключена в Supabase Auth';
    }
    if (msg.contains('email rate limit') ||
        msg.contains('rate limit') ||
        msg.contains('too many requests')) {
      return 'Слишком много попыток регистрации. Попробуйте позже.';
    }
    if (msg.contains('invalid email')) return 'Некорректный email адрес';
    if (msg.contains('password')) return 'Пароль не соответствует требованиям';
    if (kDebugMode) return 'Ошибка регистрации: $message';
    return 'Ошибка регистрации. Попробуйте позже.';
  }

  String _mapDatabaseError(PostgrestException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('row-level security') || msg.contains('rls')) {
      return 'Профиль не сохранён: RLS-политика Supabase отклонила запись';
    }
    if (msg.contains('foreign key')) {
      return 'Профиль не сохранён: пользователь Auth ещё не доступен в базе';
    }
    if (kDebugMode) return 'Ошибка базы данных: ${error.message}';
    return 'Не удалось сохранить профиль. Попробуйте позже.';
  }

  void _logSignUpError(Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('Sign-up failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _policyError = !_policyAccepted;
      _authError = null;
      _statusMessage = null;
    });
    if (!formValid || !_policyAccepted) return;

    setState(() => _loading = true);
    try {
      final response = await SupabaseService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        role: _selectedRole,
        observationStartDate: _selectedRole == UserRole.patient
            ? _observationDate
            : null,
        phone: _phoneCtrl.text.trim(),
        doctorSpecialty: _doctorSpecialtyCtrl.text.trim(),
        clinicName: _clinicCtrl.text.trim(),
      );

      final user = response.user;
      if (user == null) {
        setState(
          () => _authError =
              'Не удалось создать аккаунт. Проверьте email и попробуйте снова.',
        );
        return;
      }

      final profile = UserProfile(
        id: user.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _selectedRole,
        observationStartDate: _selectedRole == UserRole.patient
            ? _observationDate
            : DateTime.now(),
        phone: _phoneCtrl.text.trim(),
        doctorSpecialty: _doctorSpecialtyCtrl.text.trim(),
        clinicName: _clinicCtrl.text.trim(),
      );

      if (!mounted) return;
      context.read<ProfileProvider>().setLocalProfile(profile);
      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          _statusMessage =
              'Аккаунт создан. Подтвердите email, затем войдите в приложение.';
        });
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
        return;
      }

      if (!mounted) return;
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.saveProfile(profile, throwOnError: true);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => profile.isDoctor
              ? const DoctorHomeScreen()
              : const OnboardingScreen(),
        ),
      );
    } on AuthException catch (e, stackTrace) {
      _logSignUpError(e, stackTrace);
      setState(() => _authError = _mapAuthError(e.message));
    } on PostgrestException catch (e, stackTrace) {
      _logSignUpError(e, stackTrace);
      setState(() => _authError = _mapDatabaseError(e));
    } catch (e, stackTrace) {
      _logSignUpError(e, stackTrace);
      final message = kDebugMode
          ? 'Ошибка сети или приложения: $e'
          : 'Ошибка сети. Проверьте соединение.';
      setState(() => _authError = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                NLTopBar(leading: const NLBackBtn(), title: 'Регистрация'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Создать аккаунт',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: NLColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Данные хранятся в защищённом облаке',
                        style: TextStyle(fontSize: 14, color: NLColors.muted),
                      ),
                      const SizedBox(height: 22),
                      NLSegmented(
                        items: const ['Пациент', 'Врач'],
                        active: _selectedRole == UserRole.patient
                            ? 'Пациент'
                            : 'Врач',
                        onChange: (value) => setState(
                          () => _selectedRole = value == 'Врач'
                              ? UserRole.doctor
                              : UserRole.patient,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const NLLabel('Имя'),
                      _SignUpField(
                        controller: _nameCtrl,
                        hintText: 'Введите имя',
                        validator: _validateName,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),
                      const NLLabel('Email'),
                      _SignUpField(
                        controller: _emailCtrl,
                        hintText: 'example@mail.com',
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      const NLLabel('Пароль'),
                      _SignUpField(
                        controller: _passwordCtrl,
                        hintText: 'Минимум 8 символов',
                        validator: _validatePassword,
                        obscure: true,
                      ),
                      const SizedBox(height: 14),
                      if (_selectedRole == UserRole.patient) ...[
                        const NLLabel('Дата начала наблюдений'),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: NLColors.surface2,
                              borderRadius: BorderRadius.all(NLRadius.md),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatDate(_observationDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: NLColors.ink,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: NLColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const NLLabel('Специализация'),
                        _SignUpField(
                          controller: _doctorSpecialtyCtrl,
                          hintText: 'Невролог, специалист по РС',
                          validator: (_) => null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 14),
                        const NLLabel('Клиника'),
                        _SignUpField(
                          controller: _clinicCtrl,
                          hintText: 'Название клиники',
                          validator: (_) => null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 14),
                        const NLLabel('Телефон для связи'),
                        _SignUpField(
                          controller: _phoneCtrl,
                          hintText: '+7 ...',
                          validator: (_) => null,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () => setState(() {
                          _policyAccepted = !_policyAccepted;
                          if (_policyAccepted) _policyError = false;
                        }),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _policyAccepted
                                    ? NLColors.ink
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _policyError
                                      ? NLColors.bad
                                      : (_policyAccepted
                                            ? NLColors.ink
                                            : NLColors.muted),
                                  width: 1.5,
                                ),
                              ),
                              child: _policyAccepted
                                  ? const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: NLColors.ink2,
                                    height: 1.45,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Принимаю '),
                                    TextSpan(
                                      text: 'политику',
                                      style: const TextStyle(
                                        color: NLColors.accent,
                                      ),
                                      recognizer: _policyLinkRecognizer,
                                    ),
                                    const TextSpan(text: ' хранения данных'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_policyError) ...[
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Необходимо принять политику хранения данных',
                            style: TextStyle(fontSize: 12, color: NLColors.bad),
                          ),
                        ),
                      ],
                      if (_authError != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: NLColors.bad.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.all(NLRadius.md),
                          ),
                          child: Text(
                            _authError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: NLColors.bad,
                            ),
                          ),
                        ),
                      ],
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: NLColors.good.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.all(NLRadius.md),
                          ),
                          child: Text(
                            _statusMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: NLColors.good,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(
                              color: NLColors.accent,
                            ),
                          ),
                        )
                      else
                        NLButton(
                          label: 'Создать аккаунт',
                          full: true,
                          onTap: _submit,
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _SignUpField({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: NLColors.ink),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: NLColors.muted),
        filled: true,
        fillColor: NLColors.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(NLRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(NLRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(NLRadius.md),
          borderSide: const BorderSide(color: NLColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(NLRadius.md),
          borderSide: const BorderSide(color: NLColors.bad, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(NLRadius.md),
          borderSide: const BorderSide(color: NLColors.bad, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 12, color: NLColors.bad),
      ),
    );
  }
}
