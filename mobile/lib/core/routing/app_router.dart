import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Features
import '../../features/auth/splash_screen.dart';
import '../../features/onboarding/award_onboarding_screen.dart';
import '../../features/auth/auth_wall_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/multi_step_register_screen.dart';
import '../../features/onboarding/permissions_wall_screen.dart';
import '../../features/interest_graph/daily_interactive_wall_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
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
        path: '/my-interests',
        builder: (context, state) => const ManageInterestsScreen(),
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
});
