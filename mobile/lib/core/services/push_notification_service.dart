import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_service.dart';

/// Background message handler — MUST be top-level function
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate
  await Firebase.initializeApp();
  debugPrint('[PushNotificationService] Background message: ${message.messageId}');
  // In-app state update happens when app resumes via getInitialMessage / onMessageOpenedApp
}

/// Android notification channels
const AndroidNotificationChannel _actionRequiredChannel = AndroidNotificationChannel(
  'bizsquare_action_required',
  'Action Required',
  description: 'Notifications that require your immediate attention',
  importance: Importance.max,
  showBadge: true,
);

const AndroidNotificationChannel _importantChannel = AndroidNotificationChannel(
  'bizsquare_important',
  'Important Updates',
  description: 'Contact Gain, Spotlight results, and important updates',
  importance: Importance.high,
  showBadge: true,
);

const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
  'bizsquare_general',
  'General',
  description: 'General BizSquare notifications',
  importance: Importance.defaultImportance,
  showBadge: true,
);

/// Singleton push notification service.
/// Handles:
///   - Firebase initialization
///   - Permission request
///   - FCM token registration to backend
///   - Token refresh
///   - Foreground local notification display
///   - Background / terminated push tap → deep link resolution
class PushNotificationService {
  static PushNotificationService? _instance;
  static PushNotificationService get instance => _instance ??= PushNotificationService._();

  PushNotificationService._();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  ApiService? _apiService;

  /// Set the ApiService instance (with auth token already set) after login.
  void setApiService(ApiService api) {
    _apiService = api;
  }

  /// Initialize Firebase, request permissions, register token, set up handlers.
  /// Call this once after user logs in (auth token must be set in ApiService first).
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Firebase init error: $e');
      return;
    }

    _initialized = true;

    try {
      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

      // Initialize local notifications for foreground display
      await _setupLocalNotifications();

      // Request permission (iOS / Android 13+)
      await _requestPermission();

      // Get and upload FCM token
      await _uploadCurrentToken();

      // Handle token refresh (device token can change)
      _fcm.onTokenRefresh.listen(_onTokenRefresh);

      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      debugPrint('[PushNotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[PushNotificationService] Push setup error (non-fatal): $e');
    }
  }

  /// Call this on app startup to handle push taps from terminated/background states.
  /// Must be called before runApp or early in main.
  static Future<void> handleInitialMessage({
    required Function(String deepLink, String notificationId) onDeepLink,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // App opened from terminated state via push tap
      final RemoteMessage? initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handlePushTap(initial, onDeepLink);
      }

      // App resumed from background via push tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handlePushTap(message, onDeepLink);
      });
    } catch (e) {
      debugPrint('[PushNotificationService] handleInitialMessage skipped/failed: $e');
    }
  }

  static void _handlePushTap(
    RemoteMessage message,
    Function(String deepLink, String notificationId) onDeepLink,
  ) {
    final deepLink = message.data['deepLink'] as String?;
    final notificationId = message.data['notificationId'] as String?;

    debugPrint('[PushNotificationService] Push tapped → deepLink=$deepLink, id=$notificationId');

    if (deepLink != null && deepLink.isNotEmpty) {
      onDeepLink(deepLink, notificationId ?? '');
    }
  }

  /// Deregisters the current FCM token on logout.
  Future<void> deregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null && _apiService != null) {
        await _apiService!.dio.delete(
          '/users/push-token',
          data: {'token': token},
        );
      }
      await _fcm.deleteToken();
      debugPrint('[PushNotificationService] Token deregistered.');
    } catch (e) {
      debugPrint('[PushNotificationService] Deregister error (non-fatal): $e');
    }
  }

  // ─── Private Helpers ────────────────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We handle permission separately
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create Android channels
    if (Platform.isAndroid) {
      final plugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(_actionRequiredChannel);
      await plugin?.createNotificationChannel(_importantChannel);
      await plugin?.createNotificationChannel(_generalChannel);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[PushNotificationService] Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _uploadCurrentToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _uploadToken(token);
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Token upload error (non-fatal): $e');
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('[PushNotificationService] Token refreshed.');
    await _uploadToken(newToken);
  }

  Future<void> _uploadToken(String token) async {
    try {
      if (_apiService == null) return;
      await _apiService!.dio.post('/users/push-token', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      debugPrint('[PushNotificationService] Token uploaded to backend.');
    } catch (e) {
      debugPrint('[PushNotificationService] Token upload failed (non-fatal): $e');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[PushNotificationService] Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    // Determine channel from data payload priority
    final priority = message.data['priority'] as String? ?? 'INFORMATIONAL';
    String channelId = 'bizsquare_general';
    Importance channelImportance = Importance.defaultImportance;

    if (priority == 'ACTION_REQUIRED') {
      channelId = 'bizsquare_action_required';
      channelImportance = Importance.max;
    } else if (priority == 'IMPORTANT_UPDATE') {
      channelId = 'bizsquare_important';
      channelImportance = Importance.high;
    }

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: channelImportance,
          priority: priority == 'ACTION_REQUIRED' ? Priority.high : Priority.defaultPriority,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
