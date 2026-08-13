import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/permission_state_provider.dart';
import '../../core/providers/profile_state_provider.dart';
import '../../core/widgets/avatar_picker_sheet.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_section_tile.dart';
import 'widgets/profile_setup_banner.dart';
import 'widgets/sign_out_dialog.dart';

class ProfileMainScreen extends ConsumerStatefulWidget {
  const ProfileMainScreen({super.key});

  @override
  ConsumerState<ProfileMainScreen> createState() => _ProfileMainScreenState();
}

class _ProfileMainScreenState extends ConsumerState<ProfileMainScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileStateProvider.notifier).loadProfile();
    });
  }

  void _openAvatarPicker() {
    final currentAvatarId = ref.read(profileStateProvider).profile?.avatarId ?? 1;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarPickerSheet(
        currentAvatarId: currentAvatarId,
        onAvatarSelected: (newId) async {
          await ref.read(profileStateProvider.notifier).updateProfileIdentity(avatarId: newId);
        },
      ),
    );
  }

  void _handleContinueSetup() {
    final setup = ref.read(profileStateProvider).setupStatus;
    if (!setup.profileCompleted) {
      context.push('/profile/edit');
    } else if (!setup.primaryOfferSet) {
      context.push('/profile/offers');
    } else if (!setup.interestsSet) {
      context.push('/profile/interests');
    }
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'BizSquare Support',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance with your account, weekly trade contacts, or spotlight flyer?',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedMail01,
                color: Color(0xFF0058FF),
                size: 20,
              ),
              title: Text(
                'support@bizsquare.app',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0058FF),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('mailto:support@bizsquare.app'));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                color: Color(0xFF64748B),
                size: 20,
              ),
              title: Text(
                'App Version 1.0.0 (Build 2026)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0058FF),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = ref.watch(profileStateProvider);
    final permissionState = ref.watch(permissionStateProvider);
    final profile = state.profile;

    if (state.isLoading && profile == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: ShimmerLoading(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const ShimmerCard(height: 130, borderRadius: 20),
                  const SizedBox(height: 16),
                  const ShimmerBox(height: 60, width: double.infinity, borderRadius: 16),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, __) => const ShimmerCard(height: 60, borderRadius: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final hasContactPerm = permissionState.contactsGranted;
    final primaryOfferName = profile?.primaryOffer?.name ?? 'Not configured';
    final secondaryCount = profile?.secondaryOffers.length ?? 0;
    final interestCount = profile?.baselineInterests.length ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(profileStateProvider.notifier).loadProfile(forceRefresh: true),
          color: const Color(0xFF0058FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (state.isOffline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedWifi01,
                              color: Color(0xFFF59E0B),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Offline',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Profile Header Card
                ProfileHeaderCard(
                  profile: profile,
                  onEditPressed: () => context.push('/profile/edit'),
                  onAvatarPressed: _openAvatarPicker,
                ),
                const SizedBox(height: 14),

                // 2. Profile Completion Banner
                ProfileSetupBanner(
                  setupStatus: state.setupStatus,
                  onContinue: _handleContinueSetup,
                ),
                if (!state.setupStatus.isAllCompleted) const SizedBox(height: 16),

                // SECTION 1: BUSINESS & INTERESTS
                _buildSectionHeader('Business Supply & Demand', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedCrown,
                        title: 'Business & Offers',
                        subtitle: 'Primary: $primaryOfferName ($secondaryCount secondary)',
                        onTap: () => context.push('/profile/offers'),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedTarget02,
                        title: 'Baseline Interests',
                        subtitle: '$interestCount selected categories',
                        onTap: () => context.push('/profile/interests'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 2: CONTACT GAIN & VISIBILITY
                _buildSectionHeader('Contact Gain & Visibility', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedContact01,
                        title: 'Contact Sync',
                        subtitle: hasContactPerm ? 'Phonebook synchronized' : 'Permission required',
                        badgeText: hasContactPerm ? 'Active' : 'Action Required',
                        badgeColor: hasContactPerm ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        onTap: () => context.push('/profile/contact-sync'),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedFlash,
                        title: 'Spotlight History',
                        subtitle: 'Review past community visibility flyers',
                        onTap: () => context.push('/spotlight/history'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 3: PREFERENCES & SECURITY
                _buildSectionHeader('Preferences & Security', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedNotification01,
                        title: 'Notifications',
                        subtitle: 'Turn alerts and trade notices',
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedShieldUser,
                        title: 'Privacy & Discovery',
                        subtitle: 'Community search and visibility rules',
                        onTap: () => context.push('/profile/privacy'),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedSecurityCheck,
                        title: 'Account & Security',
                        subtitle: 'PIN, credentials, and session management',
                        onTap: () => context.push('/profile/account'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 4: HELP & SESSION
                _buildSectionHeader('Support & Session', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedHelpCircle,
                        title: 'Help & Support',
                        subtitle: 'Contact support team & app details',
                        onTap: _showHelpSupportDialog,
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
                      ProfileSectionTile(
                        icon: HugeIcons.strokeRoundedLogout01,
                        title: 'Sign Out',
                        subtitle: 'End session on this device',
                        isDestructive: true,
                        onTap: () {
                          SignOutDialog.show(
                            context,
                            onConfirm: () async {
                              await ref.read(profileStateProvider.notifier).signOut();
                              if (context.mounted) {
                                context.go('/auth-wall');
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
