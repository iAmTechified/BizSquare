import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum AppIconState {
  normal,
  active,
  inactive,
  disabled,
  success,
  warning,
  error,
}

enum AppIconVariant {
  stroke,
  solid,
  bulk,
}

class AppIcon extends StatelessWidget {
  final dynamic icon;
  final double size;
  final Color? color;
  final AppIconState state;
  final AppIconVariant variant;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = 22.0,
    this.color,
    this.state = AppIconState.normal,
    this.variant = AppIconVariant.stroke,
  });

  // Common Icon Constants using Hugeicons
  static const dynamic home = HugeIcons.strokeRoundedHome01;
  static const dynamic homeSolid = HugeIcons.strokeRoundedHome01;
  
  static const dynamic contacts = HugeIcons.strokeRoundedContact01;
  static const dynamic contactsSolid = HugeIcons.strokeRoundedContact01;
  
  static const dynamic spotlight = HugeIcons.strokeRoundedFlash;
  static const dynamic spotlightSolid = HugeIcons.strokeRoundedFlash;
  
  static const dynamic profile = HugeIcons.strokeRoundedUser;
  static const dynamic profileSolid = HugeIcons.strokeRoundedUser;

  static const dynamic notification = HugeIcons.strokeRoundedNotification01;
  static const dynamic notificationUnread = HugeIcons.strokeRoundedNotification02;

  static const dynamic check = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const dynamic checkSolid = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const dynamic alert = HugeIcons.strokeRoundedAlertCircle;
  static const dynamic shield = HugeIcons.strokeRoundedShield01;
  static const dynamic share = HugeIcons.strokeRoundedShare01;
  static const dynamic history = HugeIcons.strokeRoundedClock01;
  static const dynamic chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const dynamic refresh = HugeIcons.strokeRoundedRefresh;
  static const dynamic offline = HugeIcons.strokeRoundedWifiDisconnected01;
  static const dynamic target = HugeIcons.strokeRoundedTarget01;
  static const dynamic sparkle = HugeIcons.strokeRoundedSparkles;
  static const dynamic zap = HugeIcons.strokeRoundedFlash;
  static const dynamic phone = HugeIcons.strokeRoundedCall;
  static const dynamic info = HugeIcons.strokeRoundedInformationCircle;

  Color _resolveColor(BuildContext context) {
    if (color != null) return color!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (state) {
      case AppIconState.active:
        return const Color(0xFF0058FF);
      case AppIconState.inactive:
        return isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
      case AppIconState.disabled:
        return isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      case AppIconState.success:
        return const Color(0xFF5AFF00);
      case AppIconState.warning:
        return const Color(0xFFF59E0B);
      case AppIconState.error:
        return const Color(0xFFFF0055);
      case AppIconState.normal:
        return isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _resolveColor(context);
    return HugeIcon(
      icon: icon,
      color: effectiveColor,
      size: size,
    );
  }
}
