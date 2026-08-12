import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Features
import '../../features/auth/splash_screen.dart';
import '../../features/onboarding/award_onboarding_screen.dart';
import '../../features/auth/auth_wall_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/multi_step_register_screen.dart';
import '../../features/onboarding/permissions_wall_screen.dart';
import '../../features/retention/daily_interactive_wall_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/spotlight/spotlight_screen.dart';
import '../../features/spotlight/spotlight_history_screen.dart';
import '../../features/spotlight/spotlight_content_editor_screen.dart';
import '../../features/contacts/contacts_main_screen.dart';
import '../../features/contacts/screens/contact_details_screen.dart';
import '../../features/contacts/screens/archived_contacts_screen.dart';

// Profile Features
import '../../features/profile/profile_main_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/manage_offers_screen.dart';
import '../../features/profile/screens/manage_interests_screen.dart';
import '../../features/profile/screens/contact_sync_settings_screen.dart';
import '../../features/profile/screens/notification_settings_screen.dart';
import '../../features/profile/screens/privacy_settings_screen.dart';
import '../../features/profile/screens/account_security_screen.dart';

// Main Shell Tabs
import '../../features/home/home_dashboard_screen.dart';
import '../layout/main_layout.dart';
import '../models/unified_contact_model.dart';
import '../providers/auth_state_provider.dart';

/// Protected shell routes — redirect to auth-wall if unauthenticated
const _protectedPaths = [
  '/home',
  '/contacts',
  '/spotlight',
  '/profile',
  '/notifications',
  '/contacts/archived',
  '/contacts/details',
  '/spotlight/history',
  '/spotlight/edit-content',
  '/profile/edit',
  '/profile/offers',
  '/profile/interests',
  '/profile/contact-sync',
  '/profile/notifications',
  '/profile/privacy',
  '/profile/account',
];

/// Auth-only paths — redirect to home if already authenticated
const _authOnlyPaths = [
  '/auth-wall',
  '/login',
  '/register-steps',
  '/onboarding',
];

final routerProvider = Provider<GoRouter>((ref) {
  // Notifier that GoRouter will listen to for refresh signals
  final routerListenable = _AuthStateListenable(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: routerListenable,
    redirect: (context, state) {
      final userState = ref.read(userStateProvider);
      final location = state.matchedLocation;

      final isAuthenticated = userState.isAuthenticated;
      final hasOnboarded = userState.hasOnboarded;
      final onboardingCompleted = userState.onboardingCompleted;

      // Skip splash — it handles its own routing logic
      if (location == '/splash') return null;

      // If user is authenticated but hasn't completed onboarding,
      // allow them to continue through register-steps
      if (isAuthenticated && !onboardingCompleted) {
        if (location == '/register-steps' || location == '/permissions-wall') {
          return null;
        }
        return '/register-steps';
      }

      // Authenticated user trying to access auth screens → send to home
      if (isAuthenticated && onboardingCompleted) {
        if (_authOnlyPaths.contains(location)) {
          return '/home';
        }
        return null;
      }

      // Unauthenticated user trying to access protected screens → send to auth
      if (!isAuthenticated) {
        if (_protectedPaths.any((p) => location.startsWith(p))) {
          if (hasOnboarded) {
            return '/auth-wall';
          } else {
            return '/onboarding';
          }
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const AwardOnboardingScreen(),
      ),
      GoRoute(
        path: '/auth-wall',
        builder: (context, state) => const AuthWallScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register-steps',
        builder: (context, state) => const MultiStepRegisterScreen(),
      ),
      GoRoute(
        path: '/permissions-wall',
        builder: (context, state) => const PermissionsWallScreen(),
      ),
      GoRoute(
        path: '/daily-wall',
        builder: (context, state) => const DailyInteractiveWallScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/spotlight/history',
        builder: (context, state) => const SpotlightHistoryScreen(),
      ),
      GoRoute(
        path: '/spotlight/edit-content',
        builder: (context, state) => const SpotlightContentEditorScreen(),
      ),
      GoRoute(
        path: '/contacts/details',
        builder: (context, state) {
          final contact = state.extra as UnifiedContactModel;
          return ContactDetailsScreen(contact: contact);
        },
      ),
      GoRoute(
        path: '/contacts/archived',
        builder: (context, state) => const ArchivedContactsScreen(),
      ),

      // Profile Dedicated Sub-Screens
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/offers',
        builder: (context, state) => const ManageOffersScreen(),
      ),
      GoRoute(
        path: '/profile/interests',
        builder: (context, state) => const ManageInterestsScreen(),
      ),
      GoRoute(
        path: '/profile/contact-sync',
        builder: (context, state) => const ContactSyncSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/profile/account',
        builder: (context, state) => const AccountSecurityScreen(),
      ),

      // Main Navigation Shell (4 Primary Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (context, state) => const ContactsMainScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/spotlight',
                builder: (context, state) => const SpotlightScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileMainScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return router;
});

/// Listenable that triggers GoRouter.refresh() when auth state changes
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(userStateProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.onboardingCompleted != next.onboardingCompleted) {
        notifyListeners();
      }
    });
  }
}
