import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_state_provider.dart';
import 'core/providers/permission_state_provider.dart';
import 'core/providers/notifications_state_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/unified_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire up push tap deep link handler early (before app renders)
  // This handles the terminated-state tap. GoRouter will resolve the
  // deepLink once the app is running and the user is authenticated.
  String? pendingDeepLink;
  String? pendingNotificationId;

  await PushNotificationService.handleInitialMessage(
    onDeepLink: (deepLink, notificationId) {
      pendingDeepLink = deepLink;
      pendingNotificationId = notificationId;
    },
  );

  runApp(
    ProviderScope(
      child: BizSquareApp(
        pendingDeepLink: pendingDeepLink,
        pendingNotificationId: pendingNotificationId,
      ),
    ),
  );
}

class BizSquareApp extends ConsumerStatefulWidget {
  final String? pendingDeepLink;
  final String? pendingNotificationId;

  const BizSquareApp({
    super.key,
    this.pendingDeepLink,
    this.pendingNotificationId,
  });

  @override
  ConsumerState<BizSquareApp> createState() => _BizSquareAppState();
}

class _BizSquareAppState extends ConsumerState<BizSquareApp>
    with WidgetsBindingObserver {

  String? _pendingDeepLink;
  String? _pendingNotificationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pendingDeepLink = widget.pendingDeepLink;
    _pendingNotificationId = widget.pendingNotificationId;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  /// Called when app returns to foreground.
  Future<void> _onAppResumed() async {
    // 1. Recheck OS permissions (contacts, notifications)
    await ref
        .read(permissionStateProvider.notifier)
        .checkAllPermissions();

    // 2. Refresh notifications (so bell badge and activity section stay current)
    final userState = ref.read(userStateProvider);
    if (userState.isAuthenticated) {
      await ref
          .read(notificationsStateProvider.notifier)
          .loadNotifications(isRefresh: true);
    }

    // 3. Validate auth — if the token was cleared externally log out
    if (userState.isAuthenticated && userState.jwtToken == null) {
      await ref.read(userStateProvider.notifier).logout();
    }
  }

  /// Called after user successfully authenticates.
  /// Initializes push and resolves any pending deep link from a push tap.
  Future<void> _onUserAuthenticated() async {
    final userState = ref.read(userStateProvider);
    if (!userState.isAuthenticated) return;

    // Initialize push service and unified notification foundation
    final api = ref.read(apiServiceProvider);
    PushNotificationService.instance.setApiService(api);
    await PushNotificationService.instance.initialize();
    await ref.read(unifiedNotificationServiceProvider).initialize();

    // Resolve any pending deep link from terminated-state push tap
    if (_pendingDeepLink != null) {
      final router = ref.read(routerProvider);
      final link = _pendingDeepLink!;
      final notifId = _pendingNotificationId;
      _pendingDeepLink = null;
      _pendingNotificationId = null;

      // Mark the notification read
      if (notifId != null && notifId.isNotEmpty) {
        ref.read(notificationsStateProvider.notifier).markAsRead(notifId);
      }

      // Navigate to deep link destination
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(link);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Listen for auth state changes to initialize push on login
    ref.listen(userStateProvider, (previous, next) {
      if (previous?.isAuthenticated == false && next.isAuthenticated == true) {
        _onUserAuthenticated();
      }
      if (previous?.isAuthenticated == true && next.isAuthenticated == false) {
        // Deregister push token on logout
        PushNotificationService.instance.deregisterToken();
      }
    });

    return MaterialApp.router(
      title: 'BizSquare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
