import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/contact_gain_summary_model.dart';
import '../models/spotlight_model.dart';

/// Home-specific cache. Notifications are cached by NotificationCacheService.
class HomeCacheService {
  static const _storage = FlutterSecureStorage();
  static const _kContactGainKey = 'bizsquare_cached_contact_gain';
  static const _kSpotlightKey = 'bizsquare_cached_spotlight';
  static const _kSetupStatusKey = 'bizsquare_cached_setup_status';

  static Future<void> saveContactGain(ContactGainSummaryModel summary) async {
    try {
      await _storage.write(key: _kContactGainKey, value: jsonEncode(summary.toJson()));
    } catch (_) {}
  }

  static Future<ContactGainSummaryModel?> getCachedContactGain() async {
    try {
      final str = await _storage.read(key: _kContactGainKey);
      if (str != null) {
        return ContactGainSummaryModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveSpotlight(SpotlightCurrentModel spotlight) async {
    try {
      await _storage.write(key: _kSpotlightKey, value: jsonEncode(spotlight.toJson()));
    } catch (_) {}
  }

  static Future<SpotlightCurrentModel?> getCachedSpotlight() async {
    try {
      final str = await _storage.read(key: _kSpotlightKey);
      if (str != null) {
        return SpotlightCurrentModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveSetupStatus(Map<String, dynamic> data) async {
    try {
      await _storage.write(key: _kSetupStatusKey, value: jsonEncode(data));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getCachedSetupStatus() async {
    try {
      final str = await _storage.read(key: _kSetupStatusKey);
      if (str != null) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
