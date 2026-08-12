import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/spotlight_widget_state.dart';
import '../providers/spotlight_widget_provider.dart';
import '../theme/app_theme.dart';
import 'contact_gain_widget_card.dart';

class SpotlightWidgetCard extends ConsumerWidget {
  final WidgetSize size;
  final SpotlightWidgetData? overrideData;
  final VoidCallback? onTap;

  const SpotlightWidgetCard({
    super.key,
    this.size = WidgetSize.medium,
    this.overrideData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveData = ref.watch(spotlightWidgetProvider);
    final data = overrideData ?? liveData;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            context.push(data.deepLink);
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(size == WidgetSize.small ? 14 : 18),
          decoration: _buildDecoration(data, isDark),
          child: size == WidgetSize.small
              ? _buildSmallWidget(context, data, isDark)
              : _buildMediumWidget(context, data, isDark),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(SpotlightWidgetData data, bool isDark) {
    Color borderColor;
    List<BoxShadow> shadows;

    switch (data.stateType) {
      case SpotlightWidgetStateType.yourTurn:
      case SpotlightWidgetStateType.submission:
        borderColor = const Color(0xFFF59E0B);
        shadows = [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case SpotlightWidgetStateType.verified:
        borderColor = const Color(0xFF10B981);
        shadows = [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case SpotlightWidgetStateType.waiting:
        borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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

  Widget _buildSmallWidget(BuildContext context, SpotlightWidgetData data, bool isDark) {
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
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: const Color(0xFFF59E0B),
              ),
            ),
            _buildStateIcon(data.stateType, size: 16),
          ],
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _getButtonBgColor(data.stateType),
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

  Widget _buildMediumWidget(BuildContext context, SpotlightWidgetData data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data.title,
                style: AppTheme.satoshi(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
            const Spacer(),
            _buildStatusBadge(data.stateType, isDark),
          ],
        ),
        const SizedBox(height: 12),
        Row(
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
            ElevatedButton(
              onPressed: () {
                if (onTap != null) {
                  onTap!();
                } else {
                  context.push(data.deepLink);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonBgColor(data.stateType),
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
      ],
    );
  }

  Widget _buildStateIcon(SpotlightWidgetStateType state, {double size = 18}) {
    switch (state) {
      case SpotlightWidgetStateType.yourTurn:
      case SpotlightWidgetStateType.submission:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedMegaphone01,
          color: const Color(0xFFF59E0B),
          size: size,
        );
      case SpotlightWidgetStateType.verified:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          color: const Color(0xFF10B981),
          size: size,
        );
      case SpotlightWidgetStateType.waiting:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedClock01,
          color: AppTheme.primaryBlue,
          size: size,
        );
    }
  }

  Widget _buildStatusBadge(SpotlightWidgetStateType state, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (state) {
      case SpotlightWidgetStateType.yourTurn:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        label = 'YOUR TURN';
        break;
      case SpotlightWidgetStateType.submission:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        label = 'ACTION REQUIRED';
        break;
      case SpotlightWidgetStateType.verified:
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        label = 'LIVE';
        break;
      case SpotlightWidgetStateType.waiting:
        bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        label = 'NEXT TURN';
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

  Color _getButtonBgColor(SpotlightWidgetStateType state) {
    switch (state) {
      case SpotlightWidgetStateType.yourTurn:
      case SpotlightWidgetStateType.submission:
        return const Color(0xFFF59E0B);
      case SpotlightWidgetStateType.verified:
        return const Color(0xFF10B981);
      case SpotlightWidgetStateType.waiting:
        return AppTheme.primaryBlue;
    }
  }
}
