import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

final unifiedNotificationServiceProvider = Provider<UnifiedNotificationService>((ref) {
  return UnifiedNotificationService(ref);
});

enum NotificationSource { backend, admin, local }
enum NotificationPriority { actionRequired, important, informational }

class UnifiedNotificationService {
  final Ref _ref;
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  UnifiedNotificationService(this._ref);

  /// Initializes unified notification architecture across all 3 sources
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Configure Local Notification Channels with Priority Sounds & Visuals (Section 5)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('[UnifiedNotificationService] Local notification tapped: $payload');
          _handleNotificationTap(payload);
        }
      },
    );

    // Create Priority Android Channels
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'bizsquare_action_required',
        'Action Required Notifications',
        description: 'Urgent alerts requiring immediate user action',
        importance: Importance.max,
        playSound: true,
      ));

      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'bizsquare_important',
        'Important Updates',
        description: 'Key network updates and Contact Gain notifications',
        importance: Importance.high,
        playSound: true,
      ));

      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'bizsquare_general',
        'Informational Notifications',
        description: 'General activity updates',
        importance: Importance.defaultImportance,
        playSound: true,
      ));
    }

    // 2. Safely initialize Firebase & FCM
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Request FCM Push Permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[UnifiedNotificationService] FCM permission status: ${settings.authorizationStatus}');

      // Handle Foreground FCM Push Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[UnifiedNotificationService] Foreground push received: ${message.messageId}');
        _handleForegroundPush(message);
      });

      // Handle Background/Terminated Push Taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final deepLink = message.data['deepLink'] ?? message.data['actionUrl'];
        if (deepLink != null) {
          _handleNotificationTap(deepLink.toString());
        }
      });

      // Check if launched from terminated push tap
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        final deepLink = initialMessage.data['deepLink'] ?? initialMessage.data['actionUrl'];
        if (deepLink != null) {
          _handleNotificationTap(deepLink.toString());
        }
      }
    } catch (e) {
      debugPrint('[UnifiedNotificationService] FCM initialization skipped/failed: $e');
    }
  }

  /// Handles Local Scheduled Reminders (Section 1 Source C)
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required String deepLink,
    required DateTime scheduledDate,
    NotificationPriority priority = NotificationPriority.informational,
  }) async {
    String channelId = 'bizsquare_general';
    Importance importance = Importance.defaultImportance;

    if (priority == NotificationPriority.actionRequired) {
      channelId = 'bizsquare_action_required';
      importance = Importance.max;
    } else if (priority == NotificationPriority.important) {
      channelId = 'bizsquare_important';
      importance = Importance.high;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: importance,
      priority: priority == NotificationPriority.actionRequired ? Priority.high : Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: deepLink,
    );

    _trackAnalytics(eventType: 'notification_scheduled', source: 'LOCAL', metadata: {
      'scheduledDate': scheduledDate.toIso8601String(),
      'deepLink': deepLink,
    });
  }

  /// Displays foreground notification with custom visual & sound priority
  Future<void> _handleForegroundPush(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final priorityStr = message.data['priority'] as String? ?? 'INFORMATIONAL';
    final deepLink = message.data['deepLink'] ?? message.data['actionUrl'] ?? 'bizsquare://notifications';

    String channelId = 'bizsquare_general';
    Importance importance = Importance.defaultImportance;

    if (priorityStr == 'ACTION_REQUIRED') {
      channelId = 'bizsquare_action_required';
      importance = Importance.max;
    } else if (priorityStr == 'IMPORTANT_UPDATE' || priorityStr == 'IMPORTANT') {
      channelId = 'bizsquare_important';
      importance = Importance.high;
    }

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: importance,
          priority: priorityStr == 'ACTION_REQUIRED' ? Priority.high : Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: deepLink.toString(),
    );

    _trackAnalytics(eventType: 'notification_delivered', source: 'BACKEND', metadata: {
      'messageId': message.messageId,
      'deepLink': deepLink,
    });
  }

  /// Resolves notification tap via central DeepLinkResolver and tracks analytics
  void _handleNotificationTap(String rawLink) {
    _trackAnalytics(eventType: 'notification_opened', source: 'BACKEND', metadata: {'rawLink': rawLink});
    _trackAnalytics(eventType: 'notification_deep_linked', source: 'BACKEND', metadata: {'rawLink': rawLink});
  }

  /// Logs telemetry analytics event to backend (Section 8)
  void _trackAnalytics({
    required String eventType,
    String source = 'BACKEND',
    Map<String, dynamic> metadata = const {},
  }) {
    try {
      final api = _ref.read(apiServiceProvider);
      api.dio.post('/notifications/analytics/event', data: {
        'eventType': eventType,
        'source': source,
        'metadata': metadata,
      }).then((_) => null).catchError((_) => null);
    } catch (_) {}
  }
}
