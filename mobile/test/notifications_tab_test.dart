import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizsquare/core/models/notification_model.dart';
import 'package:bizsquare/core/providers/notifications_state_provider.dart';
import 'package:bizsquare/features/notifications/notifications_screen.dart';
import 'package:bizsquare/features/notifications/widgets/notification_item_tile.dart';
import 'package:bizsquare/features/notifications/widgets/notifications_empty_state.dart';

void main() {
  group('1. InAppNotificationItem Model Tests', () {
    test('Correctly parses Contact Gain notification from JSON', () {
      final json = {
        'id': 'notif-101',
        'title': 'Your contacts are ready',
        'body': '8 new verified business contacts were added this week.',
        'type': 'contact_gain',
        'isRead': false,
        'actionUrl': '/contacts',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final item = InAppNotificationItem.fromJson(json);

      expect(item.id, 'notif-101');
      expect(item.title, 'Your contacts are ready');
      expect(item.type, NotificationType.contactGain);
      expect(item.isRead, isFalse);
      expect(item.resolvedDestinationRoute, '/contacts');
      expect(item.dateGroupKey, 'Today');
      expect(item.formattedTime, 'Just now');
    });

    test('Correctly parses Spotlight notification from JSON', () {
      final json = {
        'id': 'notif-102',
        'title': "It's your turn!",
        'body': 'Your Spotlight participation window is now live.',
        'type': 'spotlight',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      };

      final item = InAppNotificationItem.fromJson(json);

      expect(item.id, 'notif-102');
      expect(item.type, NotificationType.spotlight);
      expect(item.isRead, isTrue);
      expect(item.resolvedDestinationRoute, '/spotlight');
      expect(item.dateGroupKey, 'Yesterday');
    });

    test('Correctly assigns date group key Earlier for older notifications', () {
      final item = InAppNotificationItem(
        id: 'notif-103',
        title: 'Security alert',
        body: 'PIN updated successfully.',
        type: NotificationType.account,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(item.dateGroupKey, 'Earlier');
      expect(item.resolvedDestinationRoute, '/profile/account');
    });

    test('copyWith updates isRead state cleanly', () {
      final item = InAppNotificationItem(
        id: 'notif-104',
        title: 'System announcement',
        body: 'Welcome to BizSquare',
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final updated = item.copyWith(isRead: true, readAt: DateTime.now());
      expect(updated.isRead, isTrue);
      expect(updated.readAt, isNotNull);
    });
  });

  group('2. NotificationsState Filter & Grouping Tests', () {
    final now = DateTime.now();
    final todayItem = InAppNotificationItem(
      id: '1',
      title: 'New contacts added',
      body: '4 new partners',
      type: NotificationType.contactGain,
      isRead: false,
      createdAt: now,
    );
    final yesterdayItem = InAppNotificationItem(
      id: '2',
      title: 'Spotlight submission verified',
      body: 'Your post is now active',
      type: NotificationType.spotlight,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 1)),
    );

    test('Filters unread items when NotificationFilter.unread is set', () {
      final state = NotificationsState(
        notifications: [todayItem, yesterdayItem],
        activeFilter: NotificationFilter.unread,
        unreadCount: 1,
      );

      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.id, '1');
    });

    test('Groups notifications by Today and Yesterday accurately', () {
      final state = NotificationsState(
        notifications: [todayItem, yesterdayItem],
        activeFilter: NotificationFilter.all,
      );

      final grouped = state.groupedNotifications;
      expect(grouped.containsKey('Today'), isTrue);
      expect(grouped['Today']!.length, 1);
      expect(grouped.containsKey('Yesterday'), isTrue);
      expect(grouped['Yesterday']!.length, 1);
    });
  });

  group('3. Notifications UI Widget Tests', () {
    testWidgets('NotificationsScreen renders AppBar, filter pills and empty state component', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.byType(NotificationsEmptyState), findsOneWidget);
    });

    testWidgets('NotificationsEmptyState renders all caught up for all filter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationsEmptyState(filter: NotificationFilter.all),
          ),
        ),
      );

      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text("Important updates from BizSquare will appear here."), findsOneWidget);
    });

    testWidgets('NotificationsEmptyState renders no unread for unread filter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationsEmptyState(filter: NotificationFilter.unread),
          ),
        ),
      );

      expect(find.text("No unread notifications"), findsOneWidget);
      expect(find.text("You're all caught up."), findsOneWidget);
    });

    testWidgets('NotificationItemTile renders title, body, and unread dot', (tester) async {
      final unreadItem = InAppNotificationItem(
        id: 'tile-1',
        title: 'New Contacts Gained',
        body: '8 partners connected this week',
        type: NotificationType.contactGain,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationItemTile(item: unreadItem),
            ),
          ),
        ),
      );

      expect(find.text('New Contacts Gained'), findsOneWidget);
      expect(find.text('8 partners connected this week'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
    });
  });
}
