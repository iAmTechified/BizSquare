import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

final notificationClientServiceProvider = Provider<NotificationClientService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return NotificationClientService(api);
});

class NotificationClientService {
  final ApiService _api;

  NotificationClientService(this._api);

  /// Fetches notifications from backend with optional filter and pagination
  Future<({
    List<InAppNotificationItem> notifications,
    int unreadCount,
    int totalCount,
    bool hasMore,
  })> getNotifications({
    NotificationFilter filter = NotificationFilter.all,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _api.dio.get(
        '/notifications',
        queryParameters: {
          'filter': filter == NotificationFilter.unread ? 'unread' : 'all',
          'page': page,
          'limit': limit,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final rawList = data['notifications'] as List<dynamic>? ?? [];
        final list = rawList
            .map((e) => InAppNotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final unread = data['unreadCount'] as int? ?? 0;
        final total = data['totalCount'] as int? ?? list.length;
        final hasMore = data['hasMore'] as bool? ?? false;

        return (
          notifications: list,
          unreadCount: unread,
          totalCount: total,
          hasMore: hasMore,
        );
      }
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception('Failed to parse notifications: $e');
    }

    return (
      notifications: <InAppNotificationItem>[],
      unreadCount: 0,
      totalCount: 0,
      hasMore: false,
    );
  }

  /// Marks specified notification IDs (or all if omitted) as read
  Future<int> markAsRead([List<String>? notificationIds]) async {
    try {
      final response = await _api.dio.post(
        '/notifications/mark-read',
        data: {
          if (notificationIds != null && notificationIds.isNotEmpty)
            'notificationIds': notificationIds,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return (response.data['data']['unreadCount'] as int?) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Marks specified notification IDs as unread (undo action or swipe unread)
  Future<int> markAsUnread(List<String> notificationIds) async {
    try {
      final response = await _api.dio.post(
        '/notifications/mark-unread',
        data: {'notificationIds': notificationIds},
      );

      if (response.data != null && response.data['data'] != null) {
        return (response.data['data']['unreadCount'] as int?) ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}
