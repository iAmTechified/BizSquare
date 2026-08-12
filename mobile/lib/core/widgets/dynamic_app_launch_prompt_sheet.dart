import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/permission_state_provider.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';

enum AppLaunchPromptType {
  contactsPermission,
  notificationsPermission,
  contactGainWidget,
  spotlightWidget,
}

class DynamicAppLaunchPromptSheet extends ConsumerStatefulWidget {
  final AppLaunchPromptType promptType;
  final VoidCallback? onCompleted;

  const DynamicAppLaunchPromptSheet({
    super.key,
    required this.promptType,
    this.onCompleted,
  });

  /// Evaluates permission and widget presence, presenting the highest priority missing item.
  static Future<bool> checkAndPromptIfNeeded(BuildContext context, WidgetRef ref) async {
    final permissions = ref.read(permissionStateProvider);
    final widgetService = ref.read(widgetServiceProvider);

    // 1. Priority 1: Contacts Permission
    if (!permissions.isContactsGranted) {
      if (context.mounted) {
        await _showSheet(context, AppLaunchPromptType.contactsPermission);
        return true;
      }
    }

    // 2. Priority 2: Notifications Permission
    if (!permissions.isNotificationGranted) {
      if (context.mounted) {
        await _showSheet(context, AppLaunchPromptType.notificationsPermission);
        return true;
      }
    }

    // 3. Priority 3: Contact Gain Widget
    final isContactWidgetAdded = await widgetService.isContactWidgetInstalled();
    if (!isContactWidgetAdded) {
      if (context.mounted) {
        await _showSheet(context, AppLaunchPromptType.contactGainWidget);
        return true;
      }
    }

    // 4. Priority 4: Spotlight Widget
    final isSpotlightWidgetAdded = await widgetService.isSpotlightWidgetInstalled();
    if (!isSpotlightWidgetAdded) {
      if (context.mounted) {
        await _showSheet(context, AppLaunchPromptType.spotlightWidget);
        return true;
      }
    }

    return false;
  }

  static Future<void> _showSheet(BuildContext context, AppLaunchPromptType type) async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => DynamicAppLaunchPromptSheet(promptType: type),
    );
  }

  @override
  ConsumerState<DynamicAppLaunchPromptSheet> createState() => _DynamicAppLaunchPromptSheetState();
}

class _DynamicAppLaunchPromptSheetState extends ConsumerState<DynamicAppLaunchPromptSheet>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _loopController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  bool _isProcessing = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // Entrance Animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // Looping Pulse & Float Animation
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );
    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    setState(() => _isProcessing = true);

    try {
      if (widget.promptType == AppLaunchPromptType.contactsPermission) {
        final granted = await ref.read(permissionStateProvider.notifier).requestContactsPermission();
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isCompleted = granted;
          });
          if (granted) _dismissAfterSuccess();
        }
      } else if (widget.promptType == AppLaunchPromptType.notificationsPermission) {
        final granted = await ref.read(permissionStateProvider.notifier).requestNotificationPermission();
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isCompleted = granted;
          });
          if (granted) _dismissAfterSuccess();
        }
      } else if (widget.promptType == AppLaunchPromptType.contactGainWidget) {
        final service = ref.read(widgetServiceProvider);
        final success = await service.requestPinWidget(isSpotlight: false);
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isCompleted = success;
          });
          _dismissAfterSuccess();
        }
      } else if (widget.promptType == AppLaunchPromptType.spotlightWidget) {
        final service = ref.read(widgetServiceProvider);
        final success = await service.requestPinWidget(isSpotlight: true);
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isCompleted = success;
          });
          _dismissAfterSuccess();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _dismissAfterSuccess() {
    widget.onCompleted?.call();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final config = _getPromptConfig(widget.promptType);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Drag Indicator
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stage Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: config.accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: config.accentColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        config.badge,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: config.accentColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Looping Animated Icon Centerpiece
                    AnimatedBuilder(
                      animation: _loopController,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing Halo
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: config.accentColor.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              // Core Icon Shell
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: config.accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                  border: Border.all(
                                    color: config.accentColor.withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: _isCompleted
                                      ? const HugeIcon(
                                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                          color: Color(0xFF10B981),
                                          size: 32,
                                        )
                                      : HugeIcon(
                                          icon: config.icon,
                                          color: config.accentColor,
                                          size: 30,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Headline
                    Text(
                      _isCompleted ? 'All Set!' : config.headline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _isCompleted ? 'Preferences saved successfully.' : config.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing || _isCompleted ? null : _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : _isCompleted
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Completed',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: config.actionIcon,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    config.actionLabel,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dismiss Later Button
                    TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'Remind Me Later',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _PromptConfig _getPromptConfig(AppLaunchPromptType type) {
    switch (type) {
      case AppLaunchPromptType.contactsPermission:
        return _PromptConfig(
          badge: 'NETWORK SETUP · STEP 1 OF 3',
          headline: 'Sync Contacts to Gain Matches',
          subtitle: 'BizSquare matches your business with high-value clients across 100+ verified peer networks.',
          actionLabel: 'Allow Contacts Access',
          icon: HugeIcons.strokeRoundedContact01,
          actionIcon: HugeIcons.strokeRoundedUserCheck01,
          accentColor: AppTheme.primaryBlue,
        );
      case AppLaunchPromptType.notificationsPermission:
        return _PromptConfig(
          badge: 'REAL-TIME ALERTS · STEP 2 OF 3',
          headline: 'Enable Spotlight & Gain Alerts',
          subtitle: 'Get notified immediately when your Spotlight turn goes live and new verified contacts arrive.',
          actionLabel: 'Turn On Notifications',
          icon: HugeIcons.strokeRoundedNotification01,
          actionIcon: HugeIcons.strokeRoundedFlash,
          accentColor: const Color(0xFF7C3AED),
        );
      case AppLaunchPromptType.contactGainWidget:
        return _PromptConfig(
          badge: 'HOME SCREEN · LIVE GLANCE',
          headline: 'Add Contact Gain Widget',
          subtitle: 'Track your Contact Gain cycle and review waiting verified leads right from your home screen.',
          actionLabel: 'Add Widget to Home Screen',
          icon: HugeIcons.strokeRoundedGrid,
          actionIcon: HugeIcons.strokeRoundedSmartPhone01,
          accentColor: const Color(0xFF10B981),
        );
      case AppLaunchPromptType.spotlightWidget:
        return _PromptConfig(
          badge: 'SPOTLIGHT TURN · DYNAMIC WIDGET',
          headline: 'Pin Spotlight Widget',
          subtitle: 'Stay ahead of your campaign turns and watch network participation escalate in real-time.',
          actionLabel: 'Pin Spotlight Widget',
          icon: HugeIcons.strokeRoundedFlash,
          actionIcon: HugeIcons.strokeRoundedGrid,
          accentColor: const Color(0xFFF59E0B),
        );
    }
  }
}

class _PromptConfig {
  final String badge;
  final String headline;
  final String subtitle;
  final String actionLabel;
  final dynamic icon;
  final dynamic actionIcon;
  final Color accentColor;

  const _PromptConfig({
    required this.badge,
    required this.headline,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.actionIcon,
    required this.accentColor,
  });
}
