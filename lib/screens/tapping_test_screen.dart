import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../widgets/nl_widgets.dart';
import '../models/test_result.dart';
import '../state/test_results_provider.dart';
import 'tapping_result_screen.dart';

enum _Phase { idle, running, done }

class TappingTestScreen extends StatefulWidget {
  const TappingTestScreen({super.key});

  @override
  State<TappingTestScreen> createState() => _TappingTestScreenState();
}

class _TappingTestScreenState extends State<TappingTestScreen> {
  static const _duration = 10;

  _Phase _phase = _Phase.idle;
  int _taps = 0;
  int _secondsLeft = _duration;
  String _hand = 'Правая';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() {
    if (_phase != _Phase.idle) return;
    setState(() {
      _taps = 0;
      _secondsLeft = _duration;
      _phase = _Phase.running;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _finishTest();
      }
    });
  }

  Future<void> _finishTest() async {
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    final hand = _hand == 'Левая' ? TestHand.left : TestHand.right;
    await context.read<TestResultsProvider>().addTappingResult(
      tapsPerSecond: _taps / _duration.toDouble(),
      durationSeconds: _duration,
      hand: hand,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TappingResultScreen()),
    );
  }

  void _onTap() {
    if (_phase == _Phase.running) setState(() => _taps++);
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = _phase == _Phase.idle;
    final isRunning = _phase == _Phase.running;
    final timeStr = _secondsLeft >= 10 ? '$_secondsLeft' : '0$_secondsLeft';

    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NLTopBar(leading: NLBackBtn(), title: 'Таппинг-тест'),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer display
                  Column(children: [
                    Text(
                      isIdle ? 'ДЛИТЕЛЬНОСТЬ' : 'ОСТАЛОСЬ',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NLColors.muted,
                          letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isIdle ? '10' : timeStr,
                          style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                              color: NLColors.ink,
                              height: 1),
                        ),
                        const SizedBox(width: 6),
                        const Text('сек',
                            style: TextStyle(
                                fontSize: 18,
                                color: NLColors.muted,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 32),
                  // Big tap button
                  GestureDetector(
                    onTap: isIdle
                        ? _startTest
                        : isRunning
                            ? _onTap
                            : null,
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 236,
                        height: 236,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isRunning ? NLColors.accent : NLColors.ink)
                                .withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color:
                              isRunning ? NLColors.accent : NLColors.ink,
                          shape: BoxShape.circle,
                          boxShadow: isRunning
                              ? const [
                                  BoxShadow(
                                      color: Color(0x597B6BE8),
                                      blurRadius: 60,
                                      offset: Offset(0, 30)),
                                ]
                              : const [
                                  BoxShadow(
                                      color: Color(0x331F1B16),
                                      blurRadius: 40,
                                      offset: Offset(0, 20)),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isIdle
                              ? 'Начать'
                              : isRunning
                                  ? 'Нажимай!'
                                  : 'Готово!',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.5),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  // Tap count / hint
                  Column(children: [
                    Text(
                      isIdle ? 'Нажмите кнопку' : 'Текущее',
                      style: const TextStyle(
                          fontSize: 13, color: NLColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isIdle ? 'для начала теста' : '$_taps нажатий',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          color: NLColors.ink),
                    ),
                  ]),
                ],
              ),
            ),
            // Hand selector — disabled while test is running or done
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              child: NLSegmented(
                items: const ['Левая', 'Правая'],
                active: _hand,
                onChange: isIdle ? (v) => setState(() => _hand = v) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
