import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../state/profile_provider.dart';
import '../state/diary_provider.dart';
import '../state/test_results_provider.dart';
import '../state/settings_provider.dart';
import '../services/storage_service.dart';
import 'doctor_home_screen.dart';
import 'home_screen.dart';
import 'lock_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.load();
      if (!mounted) return;
      final profile = profileProvider.profile;
      if (profile?.isPatient == true) {
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
      final destination = profile?.isDoctor == true
          ? const DoctorHomeScreen()
          : const HomeScreen();
      final shouldLock = profile?.pinEnabled == true && hasAppPin();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              shouldLock ? LockScreen(destination: destination) : destination,
        ),
      );
      return;
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(child: CircularProgressIndicator(color: NLColors.accent)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAF7F2), Color(0xFFE8E4FB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7B6BE8), Color(0xFF4A3D7A)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4D7B6BE8),
                            blurRadius: 40,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'NeuroLife',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        color: NLColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Дневник состояния · РС',
                      style: TextStyle(fontSize: 14, color: NLColors.muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                child: Column(
                  children: [
                    NLButton(
                      label: 'Войти',
                      full: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    NLGhostButton(
                      label: 'Создать аккаунт',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
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
