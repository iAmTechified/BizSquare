import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/providers/notifications_state_provider.dart';

class NotificationItemTile extends ConsumerWidget {
  final InAppNotificationItem item;

  const NotificationItemTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unreadColor = const Color(0xFF0058FF);
    final iconColor = item.iconColor;
    final isRead = item.isRead;

    // Accessibility label
    final semanticLabel = '${isRead ? "Read" : "Unread"}. ${item.title}. ${item.body}. ${item.formattedTime}';

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (isRead) {
          ref.read(notificationsStateProvider.notifier).markAsUnread(item.id);
        } else {
          ref.read(notificationsStateProvider.notifier).markAsRead(item.id);
        }
        // Don't remove from widget tree directly; state notifier will update list
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isRead ? const Color(0xFF0058FF).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: isRead ? HugeIcons.strokeRoundedNotification01 : HugeIcons.strokeRoundedCheckmarkCircle02,
              color: isRead ? const Color(0xFF0058FF) : const Color(0xFF10B981),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isRead ? 'Mark Unread' : 'Mark Read',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isRead ? const Color(0xFF0058FF) : const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isRead ? const Color(0xFF0058FF).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              isRead ? 'Mark Unread' : 'Mark Read',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isRead ? const Color(0xFF0058FF) : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            HugeIcon(
              icon: isRead ? HugeIcons.strokeRoundedNotification01 : HugeIcons.strokeRoundedCheckmarkCircle02,
              color: isRead ? const Color(0xFF0058FF) : const Color(0xFF10B981),
              size: 22,
            ),
          ],
        ),
      ),
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            // 1. Mark as read
            if (!isRead) {
              ref.read(notificationsStateProvider.notifier).markAsRead(item.id);
            }
            // 2. Deep link to destination
            final destination = item.resolvedDestinationRoute;
            if (destination.isNotEmpty) {
              context.push(destination);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isRead
                  ? (isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA))
                  : (isDark ? const Color(0xFF161E2E) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !isRead
                    ? unreadColor.withValues(alpha: isDark ? 0.35 : 0.25)
                    : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                width: !isRead ? 1.5 : 1.0,
              ),
              boxShadow: !isRead && !isDark
                  ? [
                      BoxShadow(
                        color: unreadColor.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: !isRead
                        ? iconColor.withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: item.displayIcon,
                      color: !isRead
                          ? iconColor
                          : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Body, Timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: !isRead ? FontWeight.w800 : FontWeight.w600,
                                color: !isRead
                                    ? (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A))
                                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Smart timestamp
                          Text(
                            item.formattedTime,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: !isRead ? FontWeight.w700 : FontWeight.w500,
                              color: !isRead
                                  ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0058FF))
                                  : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Supporting Body Message
                      Text(
                        item.body,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: !isRead
                              ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))
                              : (isDark ? const Color(0xFF6B7280) : const Color(0xFF64748B)),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Unread Indicator Dot
                if (!isRead) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0058FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
