import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../state/test_results_provider.dart';

enum _Phase { idle, waiting, tapping, tooEarly, done }

class ReactionTestScreen extends StatefulWidget {
  const ReactionTestScreen({super.key});

  @override
  State<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends State<ReactionTestScreen> {
  static const _totalAttempts = 5;
  static const _minDelayMs = 1000;
  static const _maxDelayMs = 3000;
  static const _tooEarlyPauseMs = 1200;

  _Phase _phase = _Phase.idle;
  final List<int> _attempts = [];

  Timer? _delayTimer;
  Timer? _tooEarlyTimer;
  Stopwatch? _stopwatch;

  // ── Math helpers ─────────────────────────────────────────────────────────

  int _median(List<int> values) {
    final s = List<int>.from(values)..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : ((s[mid - 1] + s[mid]) / 2).round();
  }

  double _average(List<int> values) =>
      values.fold<double>(0, (acc, v) => acc + v) / values.length;

  // ── Test flow ─────────────────────────────────────────────────────────────

  void _startTest() {
    _delayTimer?.cancel();
    _tooEarlyTimer?.cancel();
    _stopwatch?.stop();
    setState(() => _attempts.clear());
    _beginAttempt();
  }

  void _beginAttempt() {
    if (!mounted) return;
    setState(() => _phase = _Phase.waiting);
    final delayMs =
        _minDelayMs + Random().nextInt(_maxDelayMs - _minDelayMs);
    _delayTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _showTarget();
    });
  }

  void _showTarget() {
    _stopwatch = Stopwatch()..start();
    setState(() => _phase = _Phase.tapping);
  }

  void _handleEarlyTap() {
    _delayTimer?.cancel();
    setState(() => _phase = _Phase.tooEarly);
    _tooEarlyTimer = Timer(
      const Duration(milliseconds: _tooEarlyPauseMs),
      () {
        if (!mounted) return;
        _beginAttempt(); // retry the same attempt — index unchanged
      },
    );
  }

  void _recordAttempt() {
    final elapsed = _stopwatch?.elapsedMilliseconds ?? 0;
    _stopwatch?.stop();
    _stopwatch = null;
    setState(() => _attempts.add(elapsed));
    if (_attempts.length >= _totalAttempts) {
      _finishTest();
    } else {
      _beginAttempt();
    }
  }

  Future<void> _finishTest() async {
    if (!mounted) return;
    setState(() => _phase = _Phase.done);

    final sorted = List<int>.from(_attempts)..sort();
    final med = _median(_attempts);
    final avg = _average(_attempts);

    final metadata = jsonEncode({
      'attempts': _attempts,
      'average': double.parse(avg.toStringAsFixed(1)),
      'median': med,
      'min': sorted.first,
      'max': sorted.last,
    });

    await context.read<TestResultsProvider>().addReactionResult(
          avgReactionMs: med.toDouble(), // median as primary value
          durationSeconds: 0,
          metadataJson: metadata,
        );
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.idle:
        _startTest();
        break;
      case _Phase.waiting:
        _handleEarlyTap();
        break;
      case _Phase.tapping:
        _recordAttempt();
        break;
      case _Phase.tooEarly:
      case _Phase.done:
        break; // ignore taps
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _tooEarlyTimer?.cancel();
    _stopwatch?.stop();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDone = _phase == _Phase.done;
    final isIdle = _phase == _Phase.idle;
    final isWaiting = _phase == _Phase.waiting;
    final isTooEarly = _phase == _Phase.tooEarly;

    // How many attempts have been recorded (0–5)
    final completed = _attempts.length;
    // Current attempt number shown during the test
    final currentNum = completed + 1;

    // ── Circle visuals ────────────────────────────────────────────────────
    final Color circleColor1;
    final Color circleColor2;
    final String circleText;
    final List<BoxShadow>? circleShadows;

    if (isTooEarly) {
      circleColor1 = NLColors.bad;
      circleColor2 = const Color(0xFF8B3A2A);
      circleText = 'Рано!';
      circleShadows = [
        BoxShadow(
            color: NLColors.bad.withValues(alpha: 0.55), blurRadius: 80)
      ];
    } else if (isWaiting) {
      circleColor1 = const Color(0xFF3A3530);
      circleColor2 = const Color(0xFF28231F);
      circleText = 'Ждите...';
      circleShadows = null;
    } else if (isDone) {
      final med = _median(_attempts);
      circleColor1 = NLColors.good;
      circleColor2 = const Color(0xFF2A5A3A);
      circleText = '$med мс';
      circleShadows = [
        BoxShadow(
            color: NLColors.good.withValues(alpha: 0.55), blurRadius: 80)
      ];
    } else {
      // idle or tapping
      circleColor1 = NLColors.accent;
      circleColor2 = const Color(0xFF4A3D7A);
      circleText = isIdle ? 'Начать' : 'Тапни!';
      circleShadows = const [
        BoxShadow(color: Color(0x997B6BE8), blurRadius: 80)
      ];
    }

    // ── Counter area ──────────────────────────────────────────────────────
    final String counterLabel;
    final String counterNum;
    final String counterSuffix;

    if (isDone) {
      final med = _median(_attempts);
      counterLabel = 'МЕДИАНА';
      counterNum = '$med';
      counterSuffix = ' мс';
    } else if (isIdle) {
      counterLabel = 'ПОПЫТКА';
      counterNum = '–';
      counterSuffix = '/5';
    } else {
      counterLabel = 'ПОПЫТКА';
      counterNum = '$currentNum';
      counterSuffix = '/5';
    }

    // ── Stats for done state ──────────────────────────────────────────────
    String statsText = '';
    if (isDone && _attempts.isNotEmpty) {
      final avg = _average(_attempts).round();
      statsText = 'Среднее: $avg мс';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1714),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar (NOT inside the tap detector)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Тест реакции',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2)),
                  ),
                ),
                const SizedBox(width: 36),
              ]),
            ),

            // ── Tappable body
            Expanded(
              child: GestureDetector(
                onTap: _onTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Attempt counter / result
                    Column(children: [
                      Text(counterLabel,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0x99FFFFFF),
                              letterSpacing: 1.1)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(counterNum,
                              style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -2,
                                  color: Colors.white,
                                  height: 1)),
                          const SizedBox(width: 4),
                          Text(counterSuffix,
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0x80FFFFFF),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ]),

                    // Average line in done state
                    if (statsText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(statsText,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0x99FFFFFF))),
                    ],

                    const SizedBox(height: 32),

                    // Circle target
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                            colors: [circleColor1, circleColor2]),
                        boxShadow: circleShadows,
                      ),
                      alignment: Alignment.center,
                      child: Text(circleText,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),

                    const SizedBox(height: 32),

                    // Attempts pills
                    Text(
                      isDone
                          ? 'Все попытки (мс)'
                          : 'Прошлые попытки (мс)',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0x99FFFFFF)),
                    ),
                    const SizedBox(height: 8),
                    if (_attempts.isEmpty)
                      const Text('–',
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0x99FFFFFF)))
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: _attempts
                            .map((v) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text('$v',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ))
                            .toList(),
                      ),

                    // Restart button (done state only)
                    if (isDone) ...[
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _startTest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Повторить',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
