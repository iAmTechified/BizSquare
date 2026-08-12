import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/contact_gain_widget_provider.dart';
import '../providers/spotlight_widget_provider.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import 'contact_gain_widget_card.dart';
import 'spotlight_widget_card.dart';

enum WidgetTypeChoice { contactGain, spotlight }

class AddWidgetBottomSheet extends ConsumerStatefulWidget {
  const AddWidgetBottomSheet({super.key});

  @override
  ConsumerState<AddWidgetBottomSheet> createState() => _AddWidgetBottomSheetState();
}

class _AddWidgetBottomSheetState extends ConsumerState<AddWidgetBottomSheet> {
  bool _isPinning = false;
  bool _pinnedSuccessfully = false;
  WidgetTypeChoice _selectedType = WidgetTypeChoice.contactGain;
  WidgetSize _selectedSize = WidgetSize.medium;

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
            content: Text('Widget added to home screen!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Long-press your phone home screen and select BizSquare to place the widget.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final liveContactData = ref.watch(contactGainWidgetProvider);
    final liveSpotlightData = ref.watch(spotlightWidgetProvider);

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

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedGrid,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
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
            'Keep your Contact Gain cycle and Spotlight features visible on your phone home screen.',
            textAlign: TextAlign.center,
            style: AppTheme.satoshi(
              fontSize: 13,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Widget Type Selector (Contact Gain vs Spotlight)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTypeChip(WidgetTypeChoice.contactGain, 'Contact Gain', isDark),
              const SizedBox(width: 10),
              _buildTypeChip(WidgetTypeChoice.spotlight, 'Spotlight', isDark),
            ],
          ),
          const SizedBox(height: 12),

          // Size Toggle Pill (Medium vs Small)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSizeOption(WidgetSize.medium, 'Medium (2x1)', isDark),
                _buildSizeOption(WidgetSize.small, 'Small (1x1)', isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Interactive Widget Preview Card
          SizedBox(
            width: _selectedSize == WidgetSize.small ? 180 : double.infinity,
            child: _selectedType == WidgetTypeChoice.contactGain
                ? ContactGainWidgetCard(
                    size: _selectedSize,
                    overrideData: liveContactData,
                    onTap: () {},
                  )
                : SpotlightWidgetCard(
                    size: _selectedSize,
                    overrideData: liveSpotlightData,
                    onTap: () {},
                  ),
          ),
          const SizedBox(height: 24),

          // Action Button
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

  Widget _buildTypeChip(WidgetTypeChoice type, String label, bool isDark) {
    final selected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _selectedType = type);
      },
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: selected ? AppTheme.primaryBlue : Colors.transparent,
      ),
      labelStyle: AppTheme.satoshi(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected
            ? AppTheme.primaryBlue
            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildSizeOption(WidgetSize size, String label, bool isDark) {
    final selected = _selectedSize == size;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTheme.satoshi(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? (isDark ? Colors.white : AppTheme.primaryBlue)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
