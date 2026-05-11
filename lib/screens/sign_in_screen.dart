import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import 'home_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              NLTopBar(leading: NLBackBtn()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('С возвращением',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                            letterSpacing: -1.0, color: NLColors.ink)),
                    const SizedBox(height: 6),
                    const Text('Войдите, чтобы продолжить наблюдение',
                        style: TextStyle(fontSize: 15, color: NLColors.muted)),
                    const SizedBox(height: 24),
                    const NLLabel('Email'),
                    NLInput(placeholder: 'name@mail.com', initialValue: 'anna@neurolife.app'),
                    const SizedBox(height: 14),
                    const NLLabel('Пароль'),
                    NLInput(placeholder: '••••••••', obscure: true, initialValue: 'password',
                      trailing: const Icon(Icons.visibility_outlined, color: NLColors.muted, size: 20)),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Забыли пароль?',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NLColors.accent)),
                    ),
                    const SizedBox(height: 22),
                    NLButton(
                      label: 'Войти',
                      full: true,
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                    ),
                    const SizedBox(height: 18),
                    Row(children: [
                      const Expanded(child: Divider(color: NLColors.line)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('или', style: TextStyle(fontSize: 12, color: NLColors.muted)),
                      ),
                      const Expanded(child: Divider(color: NLColors.line)),
                    ]),
                    const SizedBox(height: 16),
                    NLButton(
                      label: 'Продолжить с Apple',
                      full: true,
                      primary: false,
                      icon: const Icon(Icons.apple, size: 18, color: NLColors.ink),
                    ),
                    const SizedBox(height: 10),
                    NLButton(
                      label: 'Войти по Face ID',
                      full: true,
                      primary: false,
                      icon: const Icon(Icons.face_retouching_natural, size: 18, color: NLColors.ink),
                    ),
                    const SizedBox(height: 32),
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
