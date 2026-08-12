import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_theme.dart';

enum SpotlightVisualVariant {
  turnReady,
  turnActive,
  turnReminder,
  turnFinal,
  participationReceived,
  participationSubmitted,
  participationVerified,
}

/// Dynamic Branded Visual Card for Spotlight Notifications (Section 12)
class SpotlightNotificationCard extends StatelessWidget {
  final SpotlightVisualVariant variant;
  final String title;
  final String message;
  final String? timeRemainingText;
  final VoidCallback? onTap;

  const SpotlightNotificationCard({
    super.key,
    required this.variant,
    required this.title,
    required this.message,
    this.timeRemainingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final config = _getVariantConfig(variant);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.backgroundColor.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: config.accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: config.icon,
                color: config.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTheme.satoshi(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (timeRemainingText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            timeRemainingText!,
                            style: AppTheme.satoshi(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: config.accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTheme.satoshi(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: config.accentColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  _VariantConfig _getVariantConfig(SpotlightVisualVariant variant) {
    switch (variant) {
      case SpotlightVisualVariant.turnReady:
      case SpotlightVisualVariant.turnActive:
        return _VariantConfig(
          backgroundColor: AppTheme.primaryBlue,
          accentColor: AppTheme.primaryBlue,
          icon: HugeIcons.strokeRoundedMegaphone01,
        );
      case SpotlightVisualVariant.turnReminder:
        return _VariantConfig(
          backgroundColor: const Color(0xFFF59E0B),
          accentColor: const Color(0xFFF59E0B),
          icon: HugeIcons.strokeRoundedNotification01,
        );
      case SpotlightVisualVariant.turnFinal:
        return _VariantConfig(
          backgroundColor: const Color(0xFFEF4444),
          accentColor: const Color(0xFFEF4444),
          icon: HugeIcons.strokeRoundedClock01,
        );
      case SpotlightVisualVariant.participationReceived:
        return _VariantConfig(
          backgroundColor: const Color(0xFF8B5CF6),
          accentColor: const Color(0xFF8B5CF6),
          icon: HugeIcons.strokeRoundedUserGroup,
        );
      case SpotlightVisualVariant.participationSubmitted:
        return _VariantConfig(
          backgroundColor: const Color(0xFF3B82F6),
          accentColor: const Color(0xFF3B82F6),
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
        );
      case SpotlightVisualVariant.participationVerified:
        return _VariantConfig(
          backgroundColor: const Color(0xFF10B981),
          accentColor: const Color(0xFF10B981),
          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        );
    }
  }
}

class _VariantConfig {
  final Color backgroundColor;
  final Color accentColor;
  final dynamic icon;

  _VariantConfig({
    required this.backgroundColor,
    required this.accentColor,
    required this.icon,
  });
}
