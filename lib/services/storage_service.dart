import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/diary_entry.dart';
import '../models/test_result.dart';
import '../models/app_settings.dart';

// Box names
const _boxProfile = 'user_profile';
const _boxDiary = 'diary_entries';
const _boxTests = 'test_results';
const _boxSettings = 'app_settings';

// Singleton keys for profile and settings (each has exactly one record)
const _keyProfile = 'profile';
const _keySettings = 'settings';

const _uuid = Uuid();

/// Initialises Hive and opens all boxes.
/// Call this once in main() before runApp().
Future<void> initStorage() async {
  await Hive.initFlutter();
  await Hive.openBox(_boxProfile);
  await Hive.openBox(_boxDiary);
  await Hive.openBox(_boxTests);
  await Hive.openBox(_boxSettings);
}

// ─── User Profile ────────────────────────────────────────────────────────────

Future<void> saveUserProfile(UserProfile profile) async {
  final box = Hive.box(_boxProfile);
  await box.put(_keyProfile, jsonEncode(profile.toJson()));
}

UserProfile? getUserProfile() {
  final box = Hive.box(_boxProfile);
  final raw = box.get(_keyProfile) as String?;
  if (raw == null) return null;
  return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<void> updateUserProfile(UserProfile profile) => saveUserProfile(profile);

Future<void> deleteUserProfile() async {
  await Hive.box(_boxProfile).delete(_keyProfile);
}

// ─── Diary Entries ───────────────────────────────────────────────────────────

/// Creates a new DiaryEntry with a generated id.
DiaryEntry createDiaryEntry({
  required DateTime dateTime,
  required int fatigue,
  required int pain,
  required int mood,
  required double sleepHours,
  String note = '',
  bool flareFlag = false,
}) =>
    DiaryEntry(
      id: _uuid.v4(),
      dateTime: dateTime,
      fatigue: fatigue,
      pain: pain,
      mood: mood,
      sleepHours: sleepHours,
      note: note,
      flareFlag: flareFlag,
    );

Future<void> addDiaryEntry(DiaryEntry entry) async {
  await Hive.box(_boxDiary).put(entry.id, jsonEncode(entry.toJson()));
}

List<DiaryEntry> getAllDiaryEntries() {
  final box = Hive.box(_boxDiary);
  final entries = box.values
      .map((raw) => DiaryEntry.fromJson(jsonDecode(raw as String) as Map<String, dynamic>))
      .toList();
  // Most recent first
  entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return entries;
}

List<DiaryEntry> getDiaryEntriesByPeriod(DateTime from, DateTime to) {
  return getAllDiaryEntries()
      .where((e) => !e.dateTime.isBefore(from) && !e.dateTime.isAfter(to))
      .toList();
}

/// Returns the entry whose date matches [date] (ignoring time), or null.
DiaryEntry? getDiaryEntryByDate(DateTime date) {
  final all = getAllDiaryEntries();
  try {
    return all.firstWhere(
      (e) =>
          e.dateTime.year == date.year &&
          e.dateTime.month == date.month &&
          e.dateTime.day == date.day,
    );
  } catch (_) {
    return null;
  }
}

Future<void> updateDiaryEntry(DiaryEntry entry) async {
  await Hive.box(_boxDiary).put(entry.id, jsonEncode(entry.toJson()));
}

Future<void> deleteDiaryEntry(String id) async {
  await Hive.box(_boxDiary).delete(id);
}

Future<void> deleteAllDiaryEntries() async {
  await Hive.box(_boxDiary).clear();
}

// ─── Test Results ─────────────────────────────────────────────────────────────

/// Creates a new TestResult with a generated id.
TestResult createTestResult({
  required String type,
  required double value,
  required int durationSeconds,
  String? hand,
  String? metadataJson,
}) =>
    TestResult(
      id: _uuid.v4(),
      type: type,
      dateTime: DateTime.now(),
      value: value,
      durationSeconds: durationSeconds,
      hand: hand,
      metadataJson: metadataJson,
    );

Future<void> addTestResult(TestResult result) async {
  await Hive.box(_boxTests).put(result.id, jsonEncode(result.toJson()));
}

List<TestResult> getAllTestResults() {
  final box = Hive.box(_boxTests);
  final results = box.values
      .map((raw) => TestResult.fromJson(jsonDecode(raw as String) as Map<String, dynamic>))
      .toList();
  results.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return results;
}

List<TestResult> getTestResultsByType(String type) {
  return getAllTestResults().where((r) => r.type == type).toList();
}

List<TestResult> getTestResultsByPeriod(DateTime from, DateTime to) {
  return getAllTestResults()
      .where((r) => !r.dateTime.isBefore(from) && !r.dateTime.isAfter(to))
      .toList();
}

Future<void> deleteTestResult(String id) async {
  await Hive.box(_boxTests).delete(id);
}

Future<void> deleteAllTestResults() async {
  await Hive.box(_boxTests).clear();
}

// ─── Settings ─────────────────────────────────────────────────────────────────

Future<void> saveSettings(AppSettings settings) async {
  await Hive.box(_boxSettings).put(_keySettings, jsonEncode(settings.toJson()));
}

/// Returns stored settings, or defaults if not yet saved.
AppSettings getSettings() {
  final raw = Hive.box(_boxSettings).get(_keySettings) as String?;
  if (raw == null) return const AppSettings();
  return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<void> updateSettings(AppSettings settings) => saveSettings(settings);

// ─── General ──────────────────────────────────────────────────────────────────

/// Wipes all local data (profile, diary, tests, settings).
Future<void> deleteAllData() async {
  await Future.wait([
    Hive.box(_boxProfile).clear(),
    Hive.box(_boxDiary).clear(),
    Hive.box(_boxTests).clear(),
    Hive.box(_boxSettings).clear(),
  ]);
}
