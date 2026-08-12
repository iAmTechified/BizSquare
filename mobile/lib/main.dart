import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_state_provider.dart';
import 'core/providers/permission_state_provider.dart';

void main() {
  runApp(const ProviderScope(child: BizSquareApp()));
}

class BizSquareApp extends ConsumerStatefulWidget {
  const BizSquareApp({super.key});

  @override
  ConsumerState<BizSquareApp> createState() => _BizSquareAppState();
}

class _BizSquareAppState extends ConsumerState<BizSquareApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  /// Rechecks permissions and validates auth state.
  Future<void> _onAppResumed() async {
    // 1. Recheck OS permissions (contacts, notifications)
    // The permission state notifier updates its internal state,
    // which homeStateProvider and contactsStateProvider already watch.
    await ref
        .read(permissionStateProvider.notifier)
        .checkAllPermissions();

    // 2. Validate auth — if the token was cleared externally
    // (e.g. from another device), the splash already handles it.
    // On resume, we verify the stored session is still valid.
    final userState = ref.read(userStateProvider);
    if (userState.isAuthenticated && userState.jwtToken == null) {
      // Token missing — log out and let the router guard redirect
      await ref.read(userStateProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'BizSquare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // System default, togglable by user
      routerConfig: router,
    );
  }
}
