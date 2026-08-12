import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single source of truth for contact sync metadata.
/// Both ProfileState and ContactsState read/write from here.
class ContactSyncCache {
  static const _storage = FlutterSecureStorage();
  static const _kLastSyncKey = 'bizsquare_contact_last_sync_at';

  /// Persists the last successful sync timestamp.
  static Future<void> saveLastSyncedAt(DateTime time) async {
    try {
      await _storage.write(key: _kLastSyncKey, value: time.toIso8601String());
    } catch (_) {}
  }

  /// Retrieves the last successful sync timestamp, or null if never synced.
  static Future<DateTime?> getLastSyncedAt() async {
    try {
      final str = await _storage.read(key: _kLastSyncKey);
      if (str != null) return DateTime.tryParse(str);
    } catch (_) {}
    return null;
  }

  /// Clears the sync timestamp (e.g. on logout/account deletion).
  static Future<void> clear() async {
    try {
      await _storage.delete(key: _kLastSyncKey);
    } catch (_) {}
  }
}
