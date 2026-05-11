import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Row(
                  children: [
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: NLColors.ink, borderRadius: BorderRadius.circular(999)))),
                    const SizedBox(width: 6),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: NLColors.ink, borderRadius: BorderRadius.circular(999)))),
                    const SizedBox(width: 6),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: NLColors.surface2, borderRadius: BorderRadius.circular(999)))),
                    const SizedBox(width: 8),
                    const Text('2 / 3', style: TextStyle(fontSize: 12, color: NLColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Зададим базовый уровень',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: NLColors.ink)),
                    const SizedBox(height: 8),
                    const Text('Среднее самочувствие за последнюю неделю. Поможет точнее отслеживать изменения.',
                        style: TextStyle(fontSize: 14, color: NLColors.muted, height: 1.5)),
                    const SizedBox(height: 22),
                    NLCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Усталость', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: NLColors.ink)),
                          const SizedBox(height: 4),
                          const Text('В среднем за неделю', style: TextStyle(fontSize: 13, color: NLColors.muted)),
                          const SizedBox(height: 14),
                          NLSlider(value: 4, color: NLColors.peach),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    NLCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Боль', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: NLColors.ink)),
                          const SizedBox(height: 4),
                          const Text('В среднем за неделю', style: TextStyle(fontSize: 13, color: NLColors.muted)),
                          const SizedBox(height: 14),
                          NLSlider(value: 3, color: NLColors.rose),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    NLCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Сон', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: NLColors.ink)),
                          const SizedBox(height: 4),
                          const Text('Часов в сутки', style: TextStyle(fontSize: 13, color: NLColors.muted)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: const [
                              Text('7.2', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.2, color: NLColors.ink)),
                              SizedBox(width: 6),
                              Text('часа', style: TextStyle(fontSize: 16, color: NLColors.muted, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    NLButton(
                      label: 'Продолжить',
                      full: true,
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
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
