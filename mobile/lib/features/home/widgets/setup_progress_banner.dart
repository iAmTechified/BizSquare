import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/providers/permission_state_provider.dart';
import '../../../../core/providers/home_state_provider.dart';

class SetupProgressBanner extends ConsumerWidget {
  final int completedSteps;
  final int totalSteps;
  final bool profileCompleted;
  final bool primaryOfferSet;
  final bool interestsSet;
  final bool contactsPermissionGranted;
  final bool notificationsPermissionGranted;

  const SetupProgressBanner({
    super.key,
    required this.completedSteps,
    this.totalSteps = 5,
    required this.profileCompleted,
    required this.primaryOfferSet,
    required this.interestsSet,
    required this.contactsPermissionGranted,
    required this.notificationsPermissionGranted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (completedSteps >= totalSteps) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine the first uncompleted step
    String title;
    String description;
    String buttonText;
    dynamic icon;
    VoidCallback onAction;

    if (!profileCompleted) {
      title = 'Complete your profile';
      description = 'Tell the community who you are and what you offer to start gaining contacts.';
      buttonText = 'Complete profile';
      icon = HugeIcons.strokeRoundedUser;
      onAction = () => context.push('/profile/edit');
    } else if (!primaryOfferSet) {
      title = 'Set your main offer';
      description = 'Define your primary micro-niche so we can connect you with relevant partners.';
      buttonText = 'Set primary offer';
      icon = HugeIcons.strokeRoundedTarget01;
      onAction = () => context.push('/profile/offers');
    } else if (!interestsSet) {
      title = 'Tell us what interests you';
      description = 'Select your supply categories to tailor the new contacts you receive weekly.';
      buttonText = 'Add interests';
      icon = HugeIcons.strokeRoundedSparkles;
      onAction = () => context.push('/profile/interests');
    } else if (!contactsPermissionGranted) {
      title = 'Allow contact access';
      description = 'We need contact access to automatically sync your Square Contacts into your phone address book.';
      buttonText = 'Allow access';
      icon = HugeIcons.strokeRoundedContact01;
      onAction = () async {
        final permNotifier = ref.read(permissionStateProvider.notifier);
        final granted = await permNotifier.requestContactsPermission();
        if (!granted) {
          final p = ref.read(permissionStateProvider);
          if (p.isContactsPermanentlyDenied && context.mounted) {
            await permNotifier.openSettings();
          }
        }
        await ref.read(homeStateProvider.notifier).refresh();
      };
    } else {
      title = 'Stay up to date';
      description = 'Enable notifications to know immediately when your weekly contacts and Spotlight arrive.';
      buttonText = 'Enable notifications';
      icon = HugeIcons.strokeRoundedNotification01;
      onAction = () async {
        await ref.read(permissionStateProvider.notifier).requestNotificationPermission();
        await ref.read(homeStateProvider.notifier).refresh();
      };
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Counter & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$completedSteps / $totalSteps COMPLETED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0058FF),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              HugeIcon(
                icon: icon,
                color: const Color(0xFF0058FF),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // CTA Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0058FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
