import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile_model.dart';

final profileCacheServiceProvider = Provider<ProfileCacheService>((ref) {
  return ProfileCacheService();
});

class ProfileCacheService {
  final FlutterSecureStorage _storage;

  static const _keyProfile = 'bizsquare_cached_profile';
  static const _keySetupStatus = 'bizsquare_cached_setup_status';
  static const _keyNotificationPrefs = 'bizsquare_cached_notification_prefs';
  static const _keyPrivacyPrefs = 'bizsquare_cached_privacy_prefs';

  ProfileCacheService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Cache latest user profile
  Future<void> cacheProfile(UserProfileModel profile) async {
    try {
      await _storage.write(
        key: _keyProfile,
        value: jsonEncode(profile.toJson()),
      );
    } catch (_) {}
  }

  /// Get cached user profile
  Future<UserProfileModel?> getCachedProfile() async {
    try {
      final jsonStr = await _storage.read(key: _keyProfile);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserProfileModel.fromJson(map);
      }
    } catch (_) {}
    return null;
  }

  /// Cache setup status flags
  Future<void> cacheSetupStatus(UserSetupStatusModel status) async {
    try {
      await _storage.write(
        key: _keySetupStatus,
        value: jsonEncode(status.toJson()),
      );
    } catch (_) {}
  }

  /// Get cached setup status
  Future<UserSetupStatusModel?> getCachedSetupStatus() async {
    try {
      final jsonStr = await _storage.read(key: _keySetupStatus);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserSetupStatusModel.fromJson(map);
      }
    } catch (_) {}
    return null;
  }

  /// Cache notification preferences
  Future<void> cacheNotificationPrefs(NotificationPreferencesModel prefs) async {
    try {
      await _storage.write(
        key: _keyNotificationPrefs,
        value: jsonEncode(prefs.toJson()),
      );
    } catch (_) {}
  }

  /// Get cached notification preferences
  Future<NotificationPreferencesModel> getNotificationPrefs() async {
    try {
      final jsonStr = await _storage.read(key: _keyNotificationPrefs);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return NotificationPreferencesModel.fromJson(map);
      }
    } catch (_) {}
    return const NotificationPreferencesModel();
  }

  /// Cache privacy preferences
  Future<void> cachePrivacyPrefs(PrivacyPreferencesModel prefs) async {
    try {
      await _storage.write(
        key: _keyPrivacyPrefs,
        value: jsonEncode(prefs.toJson()),
      );
    } catch (_) {}
  }

  /// Get cached privacy preferences
  Future<PrivacyPreferencesModel> getPrivacyPrefs() async {
    try {
      final jsonStr = await _storage.read(key: _keyPrivacyPrefs);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return PrivacyPreferencesModel.fromJson(map);
      }
    } catch (_) {}
    return const PrivacyPreferencesModel();
  }

  /// Clear profile cache upon sign out
  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _keyProfile);
      await _storage.delete(key: _keySetupStatus);
    } catch (_) {}
  }
}
