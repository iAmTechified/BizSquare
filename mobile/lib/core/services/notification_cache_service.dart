import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notification_model.dart';

class NotificationCacheService {
  static const _storage = FlutterSecureStorage();
  static const _keyNotifications = 'bizsquare_cached_notifications_v1';
  static const _keyUnreadCount = 'bizsquare_cached_unread_count_v1';

  /// Returns cached notifications from secure storage
  static Future<List<InAppNotificationItem>> getCachedNotifications() async {
    try {
      final raw = await _storage.read(key: _keyNotifications);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => InAppNotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists list of notifications to secure storage
  static Future<void> saveNotifications(List<InAppNotificationItem> notifications) async {
    try {
      final data = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await _storage.write(key: _keyNotifications, value: data);
      final unread = notifications.where((n) => !n.isRead).length;
      await _storage.write(key: _keyUnreadCount, value: unread.toString());
    } catch (_) {}
  }

  /// Returns cached unread count
  static Future<int> getCachedUnreadCount() async {
    try {
      final raw = await _storage.read(key: _keyUnreadCount);
      if (raw != null) return int.tryParse(raw) ?? 0;
      final notifs = await getCachedNotifications();
      return notifs.where((n) => !n.isRead).length;
    } catch (_) {
      return 0;
    }
  }

  /// Updates single notification read state in cache
  static Future<void> updateItemReadState(String id, bool isRead) async {
    try {
      final list = await getCachedNotifications();
      final updated = list.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: isRead, readAt: isRead ? DateTime.now() : null);
        }
        return n;
      }).toList();
      await saveNotifications(updated);
    } catch (_) {}
  }

  /// Marks all notifications as read in cache
  static Future<void> markAllAsReadInCache() async {
    try {
      final list = await getCachedNotifications();
      final updated = list
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      await saveNotifications(updated);
    } catch (_) {}
  }

  /// Clears cache on logout
  static Future<void> clearCache() async {
    try {
      await _storage.delete(key: _keyNotifications);
      await _storage.delete(key: _keyUnreadCount);
    } catch (_) {}
  }
}
