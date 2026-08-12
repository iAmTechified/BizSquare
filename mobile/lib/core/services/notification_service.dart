import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class BizNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  BizNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

final inAppNotificationsProvider = StateNotifierProvider<NotificationNotifier, List<BizNotification>>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<List<BizNotification>> {
  NotificationNotifier() : super([
    BizNotification(
      id: 'welcome_1',
      title: 'Your Business Engine is Active',
      body: '3 new qualified buyers in your category are exploring connections. Open BizSquare to review today\'s matches.',
      timestamp: DateTime.now(),
    ),
  ]);

  void addNotification(BizNotification notif) {
    state = [notif, ...state];
  }

  void markAllAsRead() {
    state = state.map((n) => BizNotification(
      id: n.id,
      title: n.title,
      body: n.body,
      timestamp: n.timestamp,
      isRead: true,
    )).toList();
  }
}

class NotificationService {
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  void showWelcomeNotificationBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF161E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your Business Engine is Active',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: 2),
            Text(
              '3 new qualified buyers in your category are exploring connections. Open BizSquare to review today\'s matches.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
