import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _loading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  bool get hasProfile => _profile != null;
  bool get isOnboarded => _profile != null;
  bool get isDoctor => _profile?.isDoctor ?? false;
  bool get isPatient => _profile?.isPatient ?? false;

  String get avatarLetter => (_profile?.name.isNotEmpty == true)
      ? _profile!.name[0].toUpperCase()
      : '?';

  String get displayName => _profile?.name ?? '';

  int get observationDays {
    if (_profile == null) return 0;
    return DateTime.now().difference(_profile!.observationStartDate).inDays + 1;
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    _loading = true;
    notifyListeners();
    try {
      _profile = await SupabaseService.getProfile(userId);
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить профиль';
    } finally {
      _loading = false;
    }
    notifyListeners();
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> saveProfile(
    UserProfile profile, {
    bool throwOnError = false,
  }) async {
    try {
      await SupabaseService.upsertProfile(profile);
      _profile = profile;
      _error = null;
    } catch (e) {
      _error = 'Не удалось сохранить профиль';
      if (throwOnError) rethrow;
    }
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) => saveProfile(profile);

  void setLocalProfile(UserProfile profile) {
    _profile = profile;
    _error = null;
    notifyListeners();
  }

  Future<void> deleteProfile() async {
    final userId = SupabaseService.currentUserId ?? _profile?.id;
    if (userId == null) return;
    try {
      await SupabaseService.deleteProfile(userId);
      _profile = null;
      _error = null;
    } catch (e) {
      _error = 'Не удалось удалить профиль';
    }
    notifyListeners();
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await SupabaseService.signOut();
    clear();
  }

  void clear() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
