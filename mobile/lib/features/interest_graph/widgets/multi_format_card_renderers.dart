import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/wall_content_model.dart';

typedef OnOptionSelected = void Function(String optionKey, String interactionType);

/// 1. THIS_OR_THAT CARD RENDERER
class ThisOrThatCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const ThisOrThatCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final optA = item.options.isNotEmpty ? item.options[0] : null;
    final optB = item.options.length > 1 ? item.options[1] : null;

    return Column(
      children: [
        if (optA != null)
          Expanded(
            child: _buildChoiceCard(
              context: context,
              option: optA,
              badge: 'OPTION A',
              isDark: isDark,
              onTap: () => onSelect(optA.optionKey, 'select'),
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            'OR',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0058FF),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (optB != null)
          Expanded(
            child: _buildChoiceCard(
              context: context,
              option: optB,
              badge: 'OPTION B',
              isDark: isDark,
              onTap: () => onSelect(optB.optionKey, 'select'),
            ),
          ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required ContentOptionModel option,
    required String badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0058FF),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                option.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              if (option.subtext != null) ...[
                const SizedBox(height: 4),
                Text(
                  option.subtext!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. PICK_ONE CARD RENDERER
class PickOneCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const PickOneCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      itemCount: item.options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final opt = item.options[i];
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(opt.optionKey, 'select');
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0058FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      if (opt.subtext != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          opt.subtext!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 3. WOULD_YOU CARD RENDERER
class WouldYouCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const WouldYouCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: item.options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(opt.optionKey, 'select');
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                    color: Color(0xFF0058FF),
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        if (opt.subtext != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            opt.subtext!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 4. REACTION_CARD RENDERER
class ReactionCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const ReactionCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E2E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedFlash,
                      color: Color(0xFF0058FF),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.titlePrompt,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: item.options.map((opt) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onSelect(opt.optionKey, 'react');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    foregroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    opt.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 5. SCENARIO CARD RENDERER
class ScenarioCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const ScenarioCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      itemCount: item.options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final opt = item.options[i];
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(opt.optionKey, 'select');
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTarget02,
                      color: Color(0xFF0058FF),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      if (opt.subtext != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          opt.subtext!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 6. COMPARE CARD RENDERER
class CompareCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const CompareCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ThisOrThatCardRenderer(item: item, onSelect: onSelect);
  }
}

/// 7. QUICK_OPINION CARD RENDERER
class QuickOpinionCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const QuickOpinionCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return WouldYouCardRenderer(item: item, onSelect: onSelect);
  }
}

/// 8. INTENT_CHOICE CARD RENDERER
class IntentChoiceCardRenderer extends StatelessWidget {
  final WallSessionItemModel item;
  final OnOptionSelected onSelect;

  const IntentChoiceCardRenderer({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return PickOneCardRenderer(item: item, onSelect: onSelect);
  }
}
