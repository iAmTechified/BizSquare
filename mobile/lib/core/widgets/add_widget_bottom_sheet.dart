import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import 'burning_fire_streak.dart';

class AddWidgetBottomSheet extends ConsumerStatefulWidget {
  const AddWidgetBottomSheet({super.key});

  @override
  ConsumerState<AddWidgetBottomSheet> createState() => _AddWidgetBottomSheetState();
}

class _AddWidgetBottomSheetState extends ConsumerState<AddWidgetBottomSheet> {
  bool _isPinning = false;
  bool _pinnedSuccessfully = false;

  Future<void> _handlePinWidget() async {
    setState(() => _isPinning = true);
    final service = ref.read(widgetServiceProvider);
    final success = await service.requestPinWidget();

    if (mounted) {
      setState(() {
        _isPinning = false;
        _pinnedSuccessfully = success;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Widget request sent! Check your home screen.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can also long-press your home screen and select BizSquare.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BurningFireStreak(streakDays: 7, size: 24, compact: true),
              const SizedBox(width: 8),
              Text(
                'Add BizSquare Widget',
                style: AppTheme.satoshi(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your trade streak hot and see verified WhatsApp matches directly on your home screen!',
            textAlign: TextAlign.center,
            style: AppTheme.satoshi(
              fontSize: 13,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 22),

          // Live Compact Widget Preview (Duolingo Style with Burning Flame)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF080D1A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/bizsquare_icon.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.widgets_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BizSquare',
                      style: AppTheme.satoshi(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const Spacer(),
                    const BurningFireStreak(streakDays: 7, size: 18, compact: true),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '3 New Matches Waiting',
                  style: AppTheme.satoshi(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Score: 98% · Tap to Connect with Verified Buyers',
                  style: AppTheme.satoshi(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isPinning ? null : _handlePinWidget,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isPinning
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _pinnedSuccessfully ? 'Widget Added' : 'Add to Home Screen',
                      style: AppTheme.satoshi(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: AppTheme.satoshi(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
