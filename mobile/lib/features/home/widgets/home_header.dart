import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/widgets/animated_critter_avatar.dart';
import '../../../../core/widgets/avatar_picker_sheet.dart';
import '../../../../core/services/avatar_service.dart';

class HomeHeader extends StatelessWidget {
  final String? userName;
  final String? businessName;
  final int avatarId;
  final int unreadCount;
  final bool isNewUser;

  const HomeHeader({
    super.key,
    this.userName,
    this.businessName,
    this.avatarId = 1,
    this.unreadCount = 0,
    this.isNewUser = false,
  });

  String _getGreeting() {
    if (isNewUser) return 'Welcome,';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = userName ?? businessName ?? 'Partner';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Avatar & Spacious Greeting
          Expanded(
            child: Row(
              children: [
                AnimatedCritterAvatar(
                  avatar: AvatarService.getAvatarByIndex(avatarId),
                  size: 48,
                  showGlow: false,
                  isInteractive: true,
                  onTap: () => AvatarPickerSheet.show(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Hugeicons Notification Bell with Unread Badge
          InkWell(
            onTap: () => context.push('/notifications'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    size: 22,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0058FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
