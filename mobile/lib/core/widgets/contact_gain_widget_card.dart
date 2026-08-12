import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/contact_gain_widget_state.dart';
import '../providers/contact_gain_widget_provider.dart';
import '../theme/app_theme.dart';

enum WidgetSize { small, medium }

class ContactGainWidgetCard extends ConsumerStatefulWidget {
  final WidgetSize size;
  final ContactGainWidgetData? overrideData; // Optional override for previews
  final VoidCallback? onTap;

  const ContactGainWidgetCard({
    super.key,
    this.size = WidgetSize.medium,
    this.overrideData,
    this.onTap,
  });

  @override
  ConsumerState<ContactGainWidgetCard> createState() => _ContactGainWidgetCardState();
}

class _ContactGainWidgetCardState extends ConsumerState<ContactGainWidgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveData = ref.watch(contactGainWidgetProvider);
    final data = widget.overrideData ?? liveData;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Trigger attention pulse if state is READY
    if (data.stateType == ContactGainWidgetStateType.ready) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = data.stateType == ContactGainWidgetStateType.ready ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              context.push(data.deepLink);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(widget.size == WidgetSize.small ? 14 : 18),
            decoration: _buildDecoration(data, isDark),
            child: widget.size == WidgetSize.small
                ? _buildSmallWidget(context, data, isDark)
                : _buildMediumWidget(context, data, isDark),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(ContactGainWidgetData data, bool isDark) {
    Color borderColor;
    List<BoxShadow> shadows;

    switch (data.stateType) {
      case ContactGainWidgetStateType.ready:
        borderColor = const Color(0xFF10B981);
        shadows = [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case ContactGainWidgetStateType.setupRequired:
        borderColor = const Color(0xFFF59E0B);
        shadows = [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case ContactGainWidgetStateType.error:
        borderColor = const Color(0xFFEF4444);
        shadows = [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case ContactGainWidgetStateType.processing:
        borderColor = AppTheme.primaryBlue;
        shadows = [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case ContactGainWidgetStateType.offline:
        borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        shadows = [];
        break;
      case ContactGainWidgetStateType.completed:
      case ContactGainWidgetStateType.waiting:
        borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
    }

    return BoxDecoration(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: shadows,
    );
  }

  // ─── SMALL WIDGET (1x1 / 2x2 Compact) ──────────────────────────────────────

  Widget _buildSmallWidget(BuildContext context, ContactGainWidgetData data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data.title,
              style: AppTheme.satoshi(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppTheme.primaryBlue,
              ),
            ),
            _buildStateIcon(data.stateType, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(data.stateType),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.contactCount > 0) ...[
                Text(
                  data.stateType == ContactGainWidgetStateType.ready
                      ? '+${data.contactCount}'
                      : '${data.contactCount}',
                  style: AppTheme.satoshi(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: data.stateType == ContactGainWidgetStateType.ready
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                Text(
                  'Contacts',
                  style: AppTheme.satoshi(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ] else ...[
                Text(
                  data.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.satoshi(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _getButtonBgColor(data.stateType, isDark),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            data.actionLabel,
            style: AppTheme.satoshi(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─── MEDIUM WIDGET (2x1 / 4x2 Focused Banner) ────────────────────────────────

  Widget _buildMediumWidget(BuildContext context, ContactGainWidgetData data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row: Brand + Status Pill
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data.title,
                style: AppTheme.satoshi(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            if (data.isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OFFLINE',
                  style: AppTheme.satoshi(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
            const Spacer(),
            _buildStatusBadge(data.stateType, isDark),
          ],
        ),
        const SizedBox(height: 12),

        // Content Row: Headline / Subtitle + Count Badge + Action Button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey(data.stateType),
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.headline,
                      style: AppTheme.satoshi(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.satoshi(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action CTA
              ElevatedButton(
                onPressed: () {
                  if (widget.onTap != null) {
                    widget.onTap!();
                  } else {
                    context.push(data.deepLink);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonBgColor(data.stateType, isDark),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  data.actionLabel,
                  style: AppTheme.satoshi(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildStateIcon(ContactGainWidgetStateType state, {double size = 18}) {
    switch (state) {
      case ContactGainWidgetStateType.ready:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedUserCheck01,
          color: const Color(0xFF10B981),
          size: size,
        );
      case ContactGainWidgetStateType.setupRequired:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedAlert02,
          color: const Color(0xFFF59E0B),
          size: size,
        );
      case ContactGainWidgetStateType.error:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedAlert02,
          color: const Color(0xFFEF4444),
          size: size,
        );
      case ContactGainWidgetStateType.processing:
        return SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryBlue,
          ),
        );
      case ContactGainWidgetStateType.offline:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedWifiDisconnected01,
          color: const Color(0xFF64748B),
          size: size,
        );
      case ContactGainWidgetStateType.completed:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedUserCheck01,
          color: AppTheme.primaryBlue,
          size: size,
        );
      case ContactGainWidgetStateType.waiting:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedClock01,
          color: AppTheme.primaryBlue,
          size: size,
        );
    }
  }

  Widget _buildStatusBadge(ContactGainWidgetStateType state, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (state) {
      case ContactGainWidgetStateType.ready:
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        label = 'READY';
        break;
      case ContactGainWidgetStateType.setupRequired:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        label = 'ACTION REQUIRED';
        break;
      case ContactGainWidgetStateType.error:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        label = 'SYNC ISSUE';
        break;
      case ContactGainWidgetStateType.processing:
        bg = AppTheme.primaryBlue.withValues(alpha: 0.15);
        fg = AppTheme.primaryBlue;
        label = 'BUILDING';
        break;
      case ContactGainWidgetStateType.offline:
        bg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        label = 'CACHED';
        break;
      case ContactGainWidgetStateType.completed:
        bg = AppTheme.primaryBlue.withValues(alpha: 0.12);
        fg = AppTheme.primaryBlue;
        label = 'SYNCED';
        break;
      case ContactGainWidgetStateType.waiting:
        bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        label = 'CYCLE WAITING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStateIcon(state, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.satoshi(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonBgColor(ContactGainWidgetStateType state, bool isDark) {
    switch (state) {
      case ContactGainWidgetStateType.ready:
        return const Color(0xFF10B981);
      case ContactGainWidgetStateType.setupRequired:
        return const Color(0xFFF59E0B);
      case ContactGainWidgetStateType.error:
        return const Color(0xFFEF4444);
      case ContactGainWidgetStateType.processing:
      case ContactGainWidgetStateType.completed:
      case ContactGainWidgetStateType.waiting:
      case ContactGainWidgetStateType.offline:
        return AppTheme.primaryBlue;
    }
  }
}
