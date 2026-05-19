import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/storage_service.dart';

class LockScreen extends StatefulWidget {
  final Widget destination;

  const LockScreen({super.key, required this.destination});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;

  void _addDigit(int digit) {
    if (_pin.length >= 4) return;
    final next = '$_pin$digit';
    setState(() {
      _pin = next;
      _error = null;
    });
    if (next.length == 4) _checkPin(next);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _checkPin(String pin) {
    if (verifyAppPin(pin)) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => widget.destination),
        (_) => false,
      );
      return;
    }
    setState(() {
      _pin = '';
      _error = 'Неверный PIN';
    });
  }

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
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: NLColors.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Введите PIN-код',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: NLColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Чтобы продолжить',
                style: TextStyle(fontSize: 14, color: NLColors.muted),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? NLColors.ink
                          : Colors.transparent,
                      border: Border.all(color: NLColors.ink, width: 2),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    _error ?? '',
                    style: const TextStyle(fontSize: 13, color: NLColors.bad),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (final row in [
                      [1, 2, 3],
                      [4, 5, 6],
                      [7, 8, 9],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row
                              .map(
                                (n) => _KeypadKey(
                                  label: '$n',
                                  onTap: () => _addDigit(n),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 88, height: 60),
                        _KeypadKey(label: '0', onTap: () => _addDigit(0)),
                        _KeypadKey(
                          icon: Icons.backspace_outlined,
                          onTap: _backspace,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _KeypadKey({this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 60,
        decoration: BoxDecoration(
          color: NLColors.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: icon == null
            ? Text(
                label ?? '',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: NLColors.ink,
                ),
              )
            : Icon(icon, size: 22, color: NLColors.ink),
      ),
    );
  }
}
