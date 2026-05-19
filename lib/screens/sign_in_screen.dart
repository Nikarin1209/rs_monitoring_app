import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../state/profile_provider.dart';
import '../state/diary_provider.dart';
import '../state/test_results_provider.dart';
import '../state/settings_provider.dart';
import '../widgets/nl_widgets.dart';
import '../models/user_profile.dart';
import 'doctor_home_screen.dart';
import 'home_screen.dart';
import 'lock_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String _selectedRole = UserRole.patient;
  String? _authError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('wrong password') ||
        msg.contains('user not found')) {
      return 'Неверный email или пароль';
    }
    if (msg.contains('email not confirmed')) {
      return 'Подтвердите email перед входом';
    }
    if (msg.contains('too many requests')) {
      return 'Слишком много попыток. Попробуйте позже.';
    }
    return 'Ошибка входа. Проверьте данные и попробуйте снова.';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _authError = null;
    });
    try {
      final response = await SupabaseService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (response.user == null) {
        setState(() => _authError = 'Не удалось войти. Попробуйте снова.');
        return;
      }

      if (!mounted) return;
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.load();
      if (!mounted) return;
      final profile = profileProvider.profile;
      if (profile == null) {
        await SupabaseService.signOut();
        setState(() => _authError = 'Профиль не найден. Создайте аккаунт.');
        return;
      }
      if (profile.role != _selectedRole) {
        await SupabaseService.signOut();
        profileProvider.clear();
        setState(
          () => _authError = _selectedRole == UserRole.doctor
              ? 'Этот аккаунт зарегистрирован как пациент.'
              : 'Этот аккаунт зарегистрирован как врач.',
        );
        return;
      }

      if (profile.isPatient) {
        final diaryProvider = context.read<DiaryProvider>();
        final testResultsProvider = context.read<TestResultsProvider>();
        final settingsProvider = context.read<SettingsProvider>();
        await Future.wait([
          diaryProvider.load(),
          testResultsProvider.load(),
          settingsProvider.load(),
        ]);
      } else {
        context.read<DiaryProvider>().clear();
        context.read<TestResultsProvider>().clear();
        context.read<SettingsProvider>().clear();
      }

      if (!mounted) return;
      final destination = profile.isDoctor
          ? const DoctorHomeScreen()
          : const HomeScreen();
      final shouldLock = profile.pinEnabled && hasAppPin();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              shouldLock ? LockScreen(destination: destination) : destination,
        ),
        (_) => false,
      );
    } on AuthException catch (e) {
      setState(() => _authError = _mapAuthError(e.message));
    } catch (_) {
      setState(() => _authError = 'Ошибка сети. Проверьте соединение.');
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
                NLTopBar(leading: const NLBackBtn()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'С возвращением',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                          color: NLColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Войдите, чтобы продолжить наблюдение',
                        style: TextStyle(fontSize: 15, color: NLColors.muted),
                      ),
                      const SizedBox(height: 24),
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
                      const NLLabel('Email'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          color: NLColors.ink,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Введите email';
                          }
                          return null;
                        },
                        decoration: _fieldDecoration('name@mail.com'),
                      ),
                      const SizedBox(height: 14),
                      const NLLabel('Пароль'),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 16,
                          color: NLColors.ink,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Введите пароль';
                          return null;
                        },
                        decoration: _fieldDecoration('••••••••').copyWith(
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: NLColors.muted,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Забыли пароль?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: NLColors.accent,
                          ),
                        ),
                      ),
                      if (_authError != null) ...[
                        const SizedBox(height: 12),
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
                      const SizedBox(height: 22),
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
                        NLButton(label: 'Войти', full: true, onTap: _submit),
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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: NLColors.muted),
      filled: true,
      fillColor: NLColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }
}
