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
import '../../features/profile/my_interests_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/spotlight/spotlight_screen.dart';
import '../../features/spotlight/spotlight_history_screen.dart';
import '../../features/spotlight/spotlight_content_editor_screen.dart';

// Main Shell Tabs
import '../../features/home/home_dashboard_screen.dart';
import '../../features/crm/crm_contacts_screen.dart';
import '../../features/more/more_screen.dart';
import '../layout/main_layout.dart';
import '../../features/contacts/screens/contact_details_screen.dart';
import '../../features/contacts/screens/archived_contacts_screen.dart';
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
        builder: (context, state) => const MyInterestsScreen(),
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
                builder: (context, state) => const CrmContactsScreen(),
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
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
