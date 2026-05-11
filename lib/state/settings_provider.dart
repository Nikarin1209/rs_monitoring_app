import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

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

  /// Count of active reminders (shown in Settings tab as "3 ›").
  int get activeReminderCount {
    int count = 0;
    if (_settings.diaryReminderEnabled) count++;
    if (_settings.tappingReminderEnabled) count++;
    if (_settings.reactionReminderEnabled) count++;
    return count;
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  void load() {
    _loading = true;
    try {
      _settings = getSettings(); // returns const AppSettings() if not yet saved
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить настройки';
    } finally {
      _loading = false;
    }
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> update(AppSettings settings) async {
    try {
      await saveSettings(settings);
      _settings = settings;
      _error = null;
    } catch (e) {
      _error = 'Не удалось сохранить настройки';
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) =>
      update(_settings.copyWith(notificationsEnabled: value));

  Future<void> setDiaryReminder({bool? enabled, String? time}) =>
      update(_settings.copyWith(
        diaryReminderEnabled: enabled,
        diaryReminderTime: time,
      ));

  Future<void> setTappingReminder({bool? enabled, String? time}) =>
      update(_settings.copyWith(
        tappingReminderEnabled: enabled,
        tappingReminderTime: time,
      ));

  Future<void> setReactionReminder({bool? enabled, String? time}) =>
      update(_settings.copyWith(
        reactionReminderEnabled: enabled,
        reactionReminderTime: time,
      ));

  Future<void> setFaceIdEnabled(bool value, ProfileSettingCallback onProfile) =>
      onProfile(value);

  Future<void> resetToDefaults() => update(const AppSettings());
}

/// Callback type used by SettingsProvider to delegate privacy settings
/// (face ID / PIN) to ProfileProvider, since those live on UserProfile.
typedef ProfileSettingCallback = Future<void> Function(bool value);
