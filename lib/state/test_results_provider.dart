import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/test_result.dart';
import '../services/supabase_service.dart';

const _uuid = Uuid();

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

  TestResult? get latestTappingResult {
    for (final r in _results) {
      if (r.type == TestType.tapping) return r;
    }
    return null;
  }

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

  double? averageLastDays(String type, int days) {
    final from = DateTime.now().subtract(Duration(days: days));
    final subset = getByPeriod(from, DateTime.now())
        .where((r) => r.type == type)
        .toList();
    if (subset.isEmpty) return null;
    return subset.fold<double>(0, (s, r) => s + r.value) / subset.length;
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    _loading = true;
    notifyListeners();
    try {
      _results = await SupabaseService.getTestResults(userId);
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить результаты тестов';
    } finally {
      _loading = false;
    }
    notifyListeners();
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> addResult(TestResult result) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    try {
      await SupabaseService.insertTestResult(userId, result);
      _results.insert(0, result);
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
      addResult(TestResult(
        id: _uuid.v4(),
        type: TestType.tapping,
        dateTime: DateTime.now(),
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
      addResult(TestResult(
        id: _uuid.v4(),
        type: TestType.reaction,
        dateTime: DateTime.now(),
        value: avgReactionMs,
        durationSeconds: durationSeconds,
        metadataJson: metadataJson,
      ));

  Future<void> delete(String id) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    try {
      await SupabaseService.deleteTestResult(userId, id);
      _results.removeWhere((r) => r.id == id);
      _error = null;
    } catch (e) {
      _error = 'Не удалось удалить результат';
    }
    notifyListeners();
  }

  Future<void> deleteAll() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    try {
      await SupabaseService.deleteAllTestResults(userId);
      _results = [];
      _error = null;
    } catch (e) {
      _error = 'Не удалось очистить результаты';
    }
    notifyListeners();
  }

  void clear() {
    _results = [];
    _error = null;
    notifyListeners();
  }
}
