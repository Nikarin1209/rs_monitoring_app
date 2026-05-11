import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';

class DiaryProvider extends ChangeNotifier {
  List<DiaryEntry> _entries = [];
  bool _loading = false;
  String? _error;

  /// All entries, newest first.
  List<DiaryEntry> get entries => _entries;
  List<DiaryEntry> get diaryEntriesSorted => _entries;

  bool get loading => _loading;
  String? get error => _error;
  bool get hasAnyData => _entries.isNotEmpty;

  // ─── Computed helpers ────────────────────────────────────────────────────

  /// Entry for today, or null if not yet filled in.
  DiaryEntry? get todayDiaryEntry {
    final today = DateTime.now();
    for (final e in _entries) {
      if (e.dateTime.year == today.year &&
          e.dateTime.month == today.month &&
          e.dateTime.day == today.day) {
        return e;
      }
    }
    return null;
  }

  bool get hasTodayDiaryEntry => todayDiaryEntry != null;

  /// Entries whose date falls within [from]..[to] inclusive.
  List<DiaryEntry> getByPeriod(DateTime from, DateTime to) {
    return _entries
        .where((e) => !e.dateTime.isBefore(from) && !e.dateTime.isAfter(to))
        .toList();
  }

  /// Last [days] calendar days (today backwards).
  List<DiaryEntry> lastDays(int days) {
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final start = DateTime(from.year, from.month, from.day);
    return getByPeriod(start, DateTime.now());
  }

  /// Average of [metric] over the last [days] days. Returns null if no data.
  double? averageLastDays(double Function(DiaryEntry) metric, int days) {
    final subset = lastDays(days);
    if (subset.isEmpty) return null;
    return subset.fold<double>(0, (s, e) => s + metric(e)) / subset.length;
  }

  /// Percent change of [metric] between prev window and current window.
  /// Returns null if either window has no data.
  double? percentChange(double Function(DiaryEntry) metric, int windowDays) {
    final now = DateTime.now();
    final mid = now.subtract(Duration(days: windowDays));
    final start = now.subtract(Duration(days: windowDays * 2));

    final current = getByPeriod(mid, now);
    final previous = getByPeriod(start, mid.subtract(const Duration(seconds: 1)));
    if (current.isEmpty || previous.isEmpty) return null;

    final avgCurrent = current.fold<double>(0, (s, e) => s + metric(e)) / current.length;
    final avgPrevious = previous.fold<double>(0, (s, e) => s + metric(e)) / previous.length;
    if (avgPrevious == 0) return null;
    return ((avgCurrent - avgPrevious) / avgPrevious * 100);
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  void load() {
    _loading = true;
    try {
      _entries = getAllDiaryEntries(); // sync Hive read, newest first
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить записи дневника';
    } finally {
      _loading = false;
    }
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> add(DiaryEntry entry) async {
    try {
      await addDiaryEntry(entry);
      // Keep newest-first order: insert at front if it is today or newer
      final idx = _entries.indexWhere(
          (e) => e.dateTime.isBefore(entry.dateTime));
      if (idx == -1) {
        _entries.add(entry);
      } else {
        _entries.insert(idx, entry);
      }
      _error = null;
    } catch (e) {
      _error = 'Не удалось сохранить запись';
    }
    notifyListeners();
  }

  Future<void> update(DiaryEntry entry) async {
    try {
      await updateDiaryEntry(entry);
      final idx = _entries.indexWhere((e) => e.id == entry.id);
      if (idx != -1) _entries[idx] = entry;
      _error = null;
    } catch (e) {
      _error = 'Не удалось обновить запись';
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    try {
      await deleteDiaryEntry(id);
      _entries.removeWhere((e) => e.id == id);
      _error = null;
    } catch (e) {
      _error = 'Не удалось удалить запись';
    }
    notifyListeners();
  }

  Future<void> deleteAll() async {
    try {
      await deleteAllDiaryEntries();
      _entries = [];
      _error = null;
    } catch (e) {
      _error = 'Не удалось очистить записи';
    }
    notifyListeners();
  }
}
