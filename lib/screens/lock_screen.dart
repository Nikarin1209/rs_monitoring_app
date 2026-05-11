import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'home_screen.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0, 0.6),
            colors: [Color(0xFFFAF7F2), Color(0xFFE8E4FB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: NLColors.ink, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Введите PIN-код',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: NLColors.ink)),
              const SizedBox(height: 6),
              const Text('Чтобы продолжить', style: TextStyle(fontSize: 14, color: NLColors.muted)),
              const SizedBox(height: 24),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < 3 ? NLColors.ink : Colors.transparent,
                    border: Border.all(color: NLColors.ink, width: 2),
                  ),
                )),
              ),
              const SizedBox(height: 32),
              // Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (final row in [[1,2,3],[4,5,6],[7,8,9]])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row.map((n) => _KeypadKey(label: '$n')).toList(),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 88),
                        _KeypadKey(
                          label: '0',
                          onTap: () => Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                        ),
                        SizedBox(
                          width: 88, height: 60,
                          child: Center(
                            child: Icon(Icons.face_retouching_natural, color: NLColors.accent, size: 26),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                child: const Text('Использовать Face ID',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NLColors.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _KeypadKey({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88, height: 60,
        decoration: BoxDecoration(color: NLColors.surface2, borderRadius: BorderRadius.circular(999)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: NLColors.ink)),
      ),
    );
  }
}
