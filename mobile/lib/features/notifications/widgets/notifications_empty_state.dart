import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/models/notification_model.dart';

class NotificationsEmptyState extends StatelessWidget {
  final NotificationFilter filter;
  final bool isOffline;
  final VoidCallback? onRetry;

  const NotificationsEmptyState({
    super.key,
    required this.filter,
    this.isOffline = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String title;
    String message;
    dynamic icon;
    Color iconColor;

    if (isOffline) {
      title = "You're offline";
      message = "Connect to the internet to load your latest notifications.";
      icon = HugeIcons.strokeRoundedWifi01;
      iconColor = const Color(0xFFEF4444);
    } else if (filter == NotificationFilter.unread) {
      title = "No unread notifications";
      message = "You're all caught up.";
      icon = HugeIcons.strokeRoundedCheckmarkCircle02;
      iconColor = const Color(0xFF10B981);
    } else {
      title = "You're all caught up";
      message = "Important updates from BizSquare will appear here.";
      icon = HugeIcons.strokeRoundedNotification01;
      iconColor = const Color(0xFF0058FF);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: iconColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),

            // Retry Button for offline state
            if (isOffline && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedRefresh,
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(
                  'Try again',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
