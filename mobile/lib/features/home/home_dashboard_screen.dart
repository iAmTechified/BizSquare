import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/home_state_provider.dart';
import '../../core/providers/notifications_state_provider.dart';
import '../../core/providers/permission_state_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/offline_banner.dart';
import 'widgets/setup_progress_banner.dart';
import 'widgets/contact_gain_hero_card.dart';
import 'widgets/recent_contacts_carousel.dart';
import 'widgets/spotlight_home_card.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/home_skeletons.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeStateProvider);
    final theme = Theme.of(context);

    if (homeState.isLoading && homeState.contactGain == null && homeState.spotlight == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const SafeArea(
          child: SingleChildScrollView(
            child: HomeSkeletons(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeStateProvider.notifier).refresh(),
          color: const Color(0xFF0058FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Offline State Indicator
                OfflineBanner(isOffline: homeState.isOffline),

                // 2. Home Header (Greeting + Hugeicons Notification Bell)
                HomeHeader(
                  userName: homeState.userName,
                  businessName: homeState.businessName,
                  avatarId: homeState.avatarId,
                  unreadCount: ref.watch(notificationsStateProvider).unreadCount,
                  isNewUser: homeState.isNewUser,
                ),

                // 3. Progressive Setup / Permission Banner (1/5 -> 5/5)
                SetupProgressBanner(
                  completedSteps: homeState.completedSetupSteps,
                  totalSteps: homeState.totalSetupSteps,
                  profileCompleted: homeState.profileCompleted,
                  primaryOfferSet: homeState.primaryOfferSet,
                  interestsSet: homeState.interestsSet,
                  contactsPermissionGranted: homeState.contactsPermissionGranted,
                  notificationsPermissionGranted: homeState.notificationsPermissionGranted,
                ),

                // Context-Aware Vertical Layout: If Spotlight is User's Turn, prioritize Spotlight
                if (homeState.spotlight?.isMyTurn == true) ...[
                  // User's Turn Spotlight Card (Top Priority)
                  SpotlightHomeCard(spotlight: homeState.spotlight),
                  const SizedBox(height: 6),

                  // Contact Gain Hero Card
                  ContactGainHeroCard(
                    summary: homeState.contactGain,
                    hasContactPermission: homeState.contactsPermissionGranted,
                    onFixSync: () async {
                      await ref.read(permissionStateProvider.notifier).requestContactsPermission();
                      await ref.read(homeStateProvider.notifier).refresh();
                    },
                  ),
                ] else ...[
                  // Standard Priority: Contact Gain Hero Card first
                  ContactGainHeroCard(
                    summary: homeState.contactGain,
                    hasContactPermission: homeState.contactsPermissionGranted,
                    onFixSync: () async {
                      await ref.read(permissionStateProvider.notifier).requestContactsPermission();
                      await ref.read(homeStateProvider.notifier).refresh();
                    },
                  ),

                  // New Contacts Horizontal Snapping Cards
                  if (homeState.contactGain != null && homeState.contactGain!.recentContacts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    RecentContactsCarousel(contacts: homeState.contactGain!.recentContacts),
                  ],

                  // Spotlight Community Card
                  const SizedBox(height: 6),
                  SpotlightHomeCard(spotlight: homeState.spotlight),
                ],

                // 4. Recent Activity / Notifications Section
                if (homeState.notifications.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  RecentActivitySection(notifications: homeState.notifications),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
