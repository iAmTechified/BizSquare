import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';

class ContactActionSheet extends StatelessWidget {
  final int duplicateCount;
  final VoidCallback onReviewDuplicates;
  final VoidCallback onManageLabels;
  final VoidCallback onSyncNow;

  const ContactActionSheet({
    super.key,
    this.duplicateCount = 0,
    required this.onReviewDuplicates,
    required this.onManageLabels,
    required this.onSyncNow,
  });

  static Future<void> show(
    BuildContext context, {
    int duplicateCount = 0,
    required VoidCallback onReviewDuplicates,
    required VoidCallback onManageLabels,
    required VoidCallback onSyncNow,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ContactActionSheet(
        duplicateCount: duplicateCount,
        onReviewDuplicates: onReviewDuplicates,
        onManageLabels: onManageLabels,
        onSyncNow: onSyncNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Contact Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Duplicates
            if (duplicateCount > 0)
              _buildOption(
                icon: HugeIcons.strokeRoundedUserMultiple,
                title: 'Review Duplicates',
                subtitle: '$duplicateCount possible duplicate contacts detected',
                badge: '$duplicateCount',
                onTap: () {
                  Navigator.pop(context);
                  onReviewDuplicates();
                },
                isDark: isDark,
              ),

            // Manage Labels
            _buildOption(
              icon: HugeIcons.strokeRoundedTag01,
              title: 'Manage Labels',
              subtitle: 'Organize contacts into custom categorized labels',
              onTap: () {
                Navigator.pop(context);
                onManageLabels();
              },
              isDark: isDark,
            ),

            // Archived Contacts
            _buildOption(
              icon: HugeIcons.strokeRoundedArchive,
              title: 'Archived Contacts',
              subtitle: 'View and restore previously archived contacts',
              onTap: () {
                Navigator.pop(context);
                context.push('/contacts/archived');
              },
              isDark: isDark,
            ),

            // Sync Now
            _buildOption(
              icon: HugeIcons.strokeRoundedRefresh,
              title: 'Sync Contacts Now',
              subtitle: 'Synchronize your Square Contacts with phone address book',
              onTap: () {
                Navigator.pop(context);
                onSyncNow();
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required dynamic icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF0058FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: HugeIcon(icon: icon, color: const Color(0xFF0058FF), size: 20),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0055),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: Color(0xFF94A3B8),
              size: 16,
            ),
    );
  }
}
