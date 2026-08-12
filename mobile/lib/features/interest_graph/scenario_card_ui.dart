import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class ScenarioCardScreen extends StatefulWidget {
  const ScenarioCardScreen({super.key});
  @override
  State<ScenarioCardScreen> createState() => _ScenarioCardScreenState();
}

class _ScenarioCardScreenState extends State<ScenarioCardScreen> {
  int _currentIndex = 0;

  static const List<Map<String, dynamic>> _interests = [
    {
      'icon': HugeIcons.strokeRoundedShoppingCart01,
      'title': 'Retail & Commerce',
      'desc': 'Buying and selling physical merchandise, e-commerce, and wholesale supply',
    },
    {
      'icon': HugeIcons.strokeRoundedRestaurant01,
      'title': 'Food & Beverage',
      'desc': 'Restaurants, catering, food production, and FMCG delivery',
    },
    {
      'icon': HugeIcons.strokeRoundedBriefcase01,
      'title': 'Professional Services',
      'desc': 'Consulting, legal, accounting, branding, and marketing services',
    },
    {
      'icon': HugeIcons.strokeRoundedLaptopProgramming,
      'title': 'Technology & Gadgets',
      'desc': 'Hardware, smartphones, IT services, and digital tools',
    },
    {
      'icon': HugeIcons.strokeRoundedPaintBoard,
      'title': 'Creative & Media',
      'desc': 'Design, photography, video production, and content creation',
    },
    {
      'icon': HugeIcons.strokeRoundedHealth,
      'title': 'Health & Personal Care',
      'desc': 'Healthcare, fitness, beauty, skincare, and wellness products',
    },
  ];

  void _nextCard() {
    HapticFeedback.selectionClick();
    if (_currentIndex >= _interests.length - 1) {
      HapticFeedback.mediumImpact();
      context.go('/home');
    } else {
      setState(() => _currentIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = _interests[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Select your interests',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us what business categories you want to discover',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _interests.length,
                  minHeight: 4,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0058FF)),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: item['icon'] as dynamic,
                          color: const Color(0xFF0058FF),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['desc'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _nextCard,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0058FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Interest',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
