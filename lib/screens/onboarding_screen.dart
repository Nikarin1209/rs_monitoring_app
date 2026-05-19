import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../state/profile_provider.dart';
import '../widgets/nl_widgets.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _fatigue;
  late int _pain;
  late double _sleep;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _fatigue = profile?.baselineFatigue ?? 5;
    _pain = profile?.baselinePain ?? 3;
    _sleep = profile?.baselineSleep ?? 7.0;
  }

  Future<void> _continue() async {
    if (_saving) return;
    final provider = context.read<ProfileProvider>();
    final profile = provider.profile;
    if (profile == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await provider.saveProfile(
        profile.copyWith(
          baselineFatigue: _fatigue,
          baselinePain: _pain,
          baselineSleep: _sleep,
        ),
        throwOnError: true,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить базовый уровень')),
      );
    }
  }

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
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: NLColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: NLColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: NLColors.surface2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '2 / 3',
                      style: TextStyle(
                        fontSize: 12,
                        color: NLColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Зададим базовый уровень',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: NLColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Среднее самочувствие за последнюю неделю. Поможет точнее отслеживать изменения.',
                      style: TextStyle(
                        fontSize: 14,
                        color: NLColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _BaselineScaleCard(
                      title: 'Усталость',
                      subtitle: 'В среднем за неделю',
                      value: _fatigue,
                      color: NLColors.peach,
                      onChanged: (value) => setState(() => _fatigue = value),
                    ),
                    const SizedBox(height: 14),
                    _BaselineScaleCard(
                      title: 'Боль',
                      subtitle: 'В среднем за неделю',
                      value: _pain,
                      color: NLColors.rose,
                      onChanged: (value) => setState(() => _pain = value),
                    ),
                    const SizedBox(height: 14),
                    _SleepCard(
                      value: _sleep,
                      onChanged: (value) => setState(() => _sleep = value),
                    ),
                    const SizedBox(height: 24),
                    NLButton(
                      label: _saving ? 'Сохраняю...' : 'Продолжить',
                      full: true,
                      onTap: _saving ? null : _continue,
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

class _BaselineScaleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _BaselineScaleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: NLColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: NLColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BaselineSlider(
            value: value.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            color: color,
            onChanged: (next) => onChanged(next.round()),
          ),
        ],
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _SleepCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сон',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: NLColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Часов в сутки',
            style: TextStyle(fontSize: 13, color: NLColors.muted),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  color: NLColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'часа',
                style: TextStyle(
                  fontSize: 16,
                  color: NLColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BaselineSlider(
            value: value,
            min: 0,
            max: 12,
            divisions: 24,
            color: NLColors.sky,
            onChanged: (next) => onChanged((next * 2).round() / 2),
          ),
        ],
      ),
    );
  }
}

class _BaselineSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  const _BaselineSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: color,
        inactiveTrackColor: NLColors.surface2,
        thumbColor: Colors.white,
        overlayColor: color.withValues(alpha: 0.14),
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 3,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}
