import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_gain_summary_model.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

final homeServiceProvider = Provider<HomeService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return HomeService(api);
});

class HomeService {
  final ApiService _api;

  HomeService(this._api);

  /// Fetches weekly Contact Gain summary and recent contacts
  Future<ContactGainSummaryModel> getContactGainSummary() async {
    try {
      final response = await _api.dio.get('/matching/user/summary');
      if (response.data != null && response.data['data'] != null) {
        return ContactGainSummaryModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
    } on DioException catch (_) {
      rethrow;
    }
    return const ContactGainSummaryModel(
      weeklyTarget: 0,
      gainedThisWeek: 0,
      remainingCount: 0,
      status: 'NO_CONTACTS',
      syncStatus: 'SYNCED',
      batchDate: '',
      recentContacts: [],
    );
  }

  /// Fetches backend setup step flags
  Future<Map<String, dynamic>> getUserSetupStatus() async {
    try {
      final response = await _api.dio.get('/users/setup-status');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'profileCompleted': false,
      'primaryOfferSet': false,
      'interestsSet': false,
      'onboardingCompleted': false,
    };
  }

  /// Fetches user notifications
  Future<({List<InAppNotificationItem> notifications, int unreadCount})> getNotifications() async {
    try {
      final response = await _api.dio.get('/notifications');
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = (data['notifications'] as List<dynamic>? ?? [])
            .map((e) => InAppNotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final unread = data['unreadCount'] as int? ?? 0;
        return (notifications: list, unreadCount: unread);
      }
    } catch (_) {}
    return (notifications: <InAppNotificationItem>[], unreadCount: 0);
  }

  /// Marks all notifications as read
  Future<void> markNotificationsRead([List<String>? notificationIds]) async {
    try {
      await _api.dio.post(
        '/notifications/mark-read',
        data: {'notificationIds': notificationIds},
      );
    } catch (_) {}
  }
}
