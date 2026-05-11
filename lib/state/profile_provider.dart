import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _loading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  /// True once the user has completed onboarding and saved a profile.
  bool get hasProfile => _profile != null;
  bool get isOnboarded => _profile != null;

  /// First letter of the user's name, used for avatars.
  String get avatarLetter =>
      (_profile?.name.isNotEmpty == true) ? _profile!.name[0].toUpperCase() : '?';

  /// Display name, falls back to empty string while loading.
  String get displayName => _profile?.name ?? '';

  /// How many days the patient has been under observation.
  int get observationDays {
    if (_profile == null) return 0;
    return DateTime.now().difference(_profile!.observationStartDate).inDays + 1;
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  void load() {
    _loading = true;
    // No notifyListeners here — called during provider creation, before any
    // listeners are attached. Data is read synchronously from the open Hive box.
    try {
      _profile = getUserProfile();
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить профиль';
    } finally {
      _loading = false;
    }
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> saveProfile(UserProfile profile) async {
    try {
      await saveUserProfile(profile);
      _profile = profile;
      _error = null;
    } catch (e) {
      _error = 'Не удалось сохранить профиль';
    }
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) => saveProfile(profile);

  Future<void> deleteProfile() async {
    try {
      await deleteUserProfile();
      _profile = null;
      _error = null;
    } catch (e) {
      _error = 'Не удалось удалить профиль';
    }
    notifyListeners();
  }
}
