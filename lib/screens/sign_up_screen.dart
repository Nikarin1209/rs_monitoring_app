import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/user_profile.dart';
import '../state/profile_provider.dart';
import '../widgets/nl_widgets.dart';
import 'onboarding_screen.dart';

const _uuid = Uuid();

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
  late final TapGestureRecognizer _policyLinkRecognizer;

  DateTime _observationDate = DateTime.now();
  bool _policyAccepted = false;
  bool _policyError = false;

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
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
          'Данные приложения NeuroLife хранятся локально на устройстве пользователя '
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
    if (!RegExp(r'^[А-ЯA-Z][а-яА-Яa-zA-ZёЁ]+$').hasMatch(v.trim())) {
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
    if (!RegExp(r'[a-zа-яё]').hasMatch(v)) return 'Добавьте хотя бы одну строчную букву';
    if (!RegExp(r'[A-ZА-ЯЁ]').hasMatch(v)) return 'Добавьте хотя бы одну заглавную букву';
    if (!RegExp(r'\d').hasMatch(v)) return 'Добавьте хотя бы одну цифру';
    return null;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _policyError = !_policyAccepted);
    if (!formValid || !_policyAccepted) return;

    final profile = UserProfile(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      observationStartDate: _observationDate,
    );
    await context.read<ProfileProvider>().saveProfile(profile);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
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
                        'Данные хранятся локально и зашифрованы',
                        style: TextStyle(fontSize: 14, color: NLColors.muted),
                      ),
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 18),
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

// Styled TextFormField matching NLInput visuals.
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
