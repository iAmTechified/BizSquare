import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              color: const Color(0xFF0058FF),
              onTap: () => onSelect(optA.optionKey, 'select'),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'OR',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF0058FF)),
          ),
        ),
        const SizedBox(height: 12),
        if (optB != null)
          Expanded(
            child: _buildChoiceCard(
              context: context,
              option: optB,
              badge: 'OPTION B',
              color: const Color(0xFF5AFF00),
              textColor: Colors.black87,
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
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: textColor),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                option.label,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              if (option.subtext != null) ...[
                const SizedBox(height: 4),
                Text(
                  option.subtext!,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your top choice:',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: item.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final opt = item.options[idx];
              return InkWell(
                onTap: () => onSelect(opt.optionKey, 'select'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFF0058FF)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF0058FF), fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                            if (opt.subtext != null)
                              Text(opt.subtext!, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: item.options.map((opt) {
        final isYes = opt.optionKey == 'yes';
        final isMaybe = opt.optionKey == 'maybe';
        final color = isYes ? const Color(0xFF0058FF) : isMaybe ? const Color(0xFFF59E0B) : const Color(0xFF64748B);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () => onSelect(opt.optionKey, isYes ? 'positive' : isMaybe ? 'weak_positive' : 'skip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isYes ? color : color.withValues(alpha: 0.1),
                foregroundColor: isYes ? Colors.white : color,
                elevation: isYes ? 3 : 0,
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleModal(),
              ),
              child: Text(
                opt.label,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static RoundedRectangleBorder RoundedRectangleModal() {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0058FF), Color(0xFF5AFF00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FEATURE SPOTLIGHT',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF0058FF)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.titlePrompt,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              if (item.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.description!,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: item.options.map((opt) {
            return InkWell(
              onTap: () => onSelect(opt.optionKey, 'react'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(
                  opt.label,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF00A6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: Color(0xFFFF00A6), size: 20),
              const SizedBox(width: 8),
              Text(
                'GROWTH DILEMMA',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFFFF00A6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: item.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final opt = item.options[idx];
              return InkWell(
                onTap: () => onSelect(opt.optionKey, 'select'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                      if (opt.subtext != null) ...[
                        const SizedBox(height: 4),
                        Text(opt.subtext!, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: item.options.map((opt) {
        final isNow = opt.optionKey == 'act_now';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => onSelect(opt.optionKey, isNow ? 'intent' : 'weak_positive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isNow ? const Color(0xFF0058FF) : Colors.white,
                foregroundColor: isNow ? Colors.white : Colors.black87,
                elevation: isNow ? 4 : 0,
                side: BorderSide(
                  color: isNow ? const Color(0xFF0058FF) : Colors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(opt.label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                  if (opt.subtext != null)
                    Text(
                      opt.subtext!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isNow ? Colors.white.withValues(alpha: 0.8) : Colors.grey[600],
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
