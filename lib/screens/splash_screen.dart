import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          BoxShadow(color: Color(0x4D7B6BE8), blurRadius: 40, offset: Offset(0, 20)),
                        ],
                      ),
                      child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 18),
                    const Text('NeuroLife',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                            letterSpacing: -1.0, color: NLColors.ink)),
                    const SizedBox(height: 6),
                    const Text('Дневник состояния · РС',
                        style: TextStyle(fontSize: 14, color: NLColors.muted)),
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
                          MaterialPageRoute(builder: (_) => const SignInScreen())),
                    ),
                    const SizedBox(height: 10),
                    NLGhostButton(
                      label: 'Создать аккаунт',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpScreen())),
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
