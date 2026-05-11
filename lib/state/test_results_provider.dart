import 'package:flutter/foundation.dart';
import '../models/test_result.dart';
import '../services/storage_service.dart';

class TestResultsProvider extends ChangeNotifier {
  List<TestResult> _results = [];
  bool _loading = false;
  String? _error;

  /// All results, newest first.
  List<TestResult> get results => _results;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasAnyData => _results.isNotEmpty;

  // ─── Computed helpers ────────────────────────────────────────────────────

  /// Most recent tapping result, or null.
  TestResult? get latestTappingResult {
    for (final r in _results) {
      if (r.type == TestType.tapping) return r;
    }
    return null;
  }

  /// Most recent reaction result, or null.
  TestResult? get latestReactionResult {
    for (final r in _results) {
      if (r.type == TestType.reaction) return r;
    }
    return null;
  }

  List<TestResult> getByType(String type) =>
      _results.where((r) => r.type == type).toList();

  List<TestResult> getByPeriod(DateTime from, DateTime to) => _results
      .where((r) => !r.dateTime.isBefore(from) && !r.dateTime.isAfter(to))
      .toList();

  /// Average value for [type] over the last [days] days. Returns null if no data.
  double? averageLastDays(String type, int days) {
    final from = DateTime.now().subtract(Duration(days: days));
    final subset = getByPeriod(from, DateTime.now())
        .where((r) => r.type == type)
        .toList();
    if (subset.isEmpty) return null;
    return subset.fold<double>(0, (s, r) => s + r.value) / subset.length;
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  void load() {
    _loading = true;
    try {
      _results = getAllTestResults(); // sync Hive read, newest first
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить результаты тестов';
    } finally {
      _loading = false;
    }
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> addResult(TestResult result) async {
    try {
      await addTestResult(result);
      _results.insert(0, result); // newest first
      _error = null;
    } catch (e) {
      _error = 'Не удалось сохранить результат';
    }
    notifyListeners();
  }

  Future<void> addTappingResult({
    required double tapsPerSecond,
    required int durationSeconds,
    required String hand,
    String? metadataJson,
  }) =>
      addResult(createTestResult(
        type: TestType.tapping,
        value: tapsPerSecond,
        durationSeconds: durationSeconds,
        hand: hand,
        metadataJson: metadataJson,
      ));

  Future<void> addReactionResult({
    required double avgReactionMs,
    required int durationSeconds,
    String? metadataJson,
  }) =>
      addResult(createTestResult(
        type: TestType.reaction,
        value: avgReactionMs,
        durationSeconds: durationSeconds,
        metadataJson: metadataJson,
      ));

  Future<void> delete(String id) async {
    try {
      await deleteTestResult(id);
      _results.removeWhere((r) => r.id == id);
      _error = null;
    } catch (e) {
      _error = 'Не удалось удалить результат';
    }
    notifyListeners();
  }

  Future<void> deleteAll() async {
    try {
      await deleteAllTestResults();
      _results = [];
      _error = null;
    } catch (e) {
      _error = 'Не удалось очистить результаты';
    }
    notifyListeners();
  }
}
