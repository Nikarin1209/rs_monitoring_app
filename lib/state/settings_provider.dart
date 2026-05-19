import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/supabase_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _loading = false;
  String? _error;

  AppSettings get settings => _settings;
  bool get loading => _loading;
  String? get error => _error;

  // ─── Convenience getters ─────────────────────────────────────────────────

  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get diaryReminderEnabled => _settings.diaryReminderEnabled;
  bool get tappingReminderEnabled => _settings.tappingReminderEnabled;
  bool get reactionReminderEnabled => _settings.reactionReminderEnabled;

  int get activeReminderCount {
    int count = 0;
    if (_settings.diaryReminderEnabled) count++;
    if (_settings.tappingReminderEnabled) count++;
    if (_settings.reactionReminderEnabled) count++;
    return count;
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    _loading = true;
    notifyListeners();
    try {
      _settings = await SupabaseService.getSettings(userId);
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить настройки';
    } finally {
      _loading = false;
    }
    notifyListeners();
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> update(AppSettings settings, {bool throwOnError = false}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    try {
      await SupabaseService.upsertSettings(userId, settings);
      _settings = settings;
      _error = null;
    } catch (e) {
      _error = 'Не удалось сохранить настройки';
      if (throwOnError) rethrow;
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) =>
      update(_settings.copyWith(notificationsEnabled: value));

  Future<void> setDiaryReminder({bool? enabled, String? time}) => update(
    _settings.copyWith(diaryReminderEnabled: enabled, diaryReminderTime: time),
  );

  Future<void> setTappingReminder({bool? enabled, String? time}) => update(
    _settings.copyWith(
      tappingReminderEnabled: enabled,
      tappingReminderTime: time,
    ),
  );

  Future<void> setReactionReminder({bool? enabled, String? time}) => update(
    _settings.copyWith(
      reactionReminderEnabled: enabled,
      reactionReminderTime: time,
    ),
  );

  Future<void> setScalesAndUnits({
    required int symptomScaleMax,
    required String symptomScaleUnit,
    required String sleepUnit,
    required String tappingUnit,
    bool throwOnError = false,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    final nextSettings = _settings.copyWith(
      symptomScaleMax: symptomScaleMax,
      symptomScaleUnit: symptomScaleUnit,
      sleepUnit: sleepUnit,
      tappingUnit: tappingUnit,
    );
    try {
      await SupabaseService.upsertScaleUnitSettings(
        userId,
        symptomScaleMax: nextSettings.symptomScaleMax,
        symptomScaleUnit: nextSettings.symptomScaleUnit,
        sleepUnit: nextSettings.sleepUnit,
        tappingUnit: nextSettings.tappingUnit,
      );
      _settings = nextSettings;
      _error = null;
    } catch (e) {
      _error = 'Не удалось сохранить шкалы и единицы';
      if (throwOnError) rethrow;
    }
    notifyListeners();
  }

  Future<void> setFaceIdEnabled(bool value, ProfileSettingCallback onProfile) =>
      onProfile(value);

  Future<void> resetToDefaults() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      _settings = const AppSettings();
      notifyListeners();
      return;
    }
    await update(const AppSettings());
  }

  void clear() {
    _settings = const AppSettings();
    _error = null;
    notifyListeners();
  }
}

typedef ProfileSettingCallback = Future<void> Function(bool value);
