import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_state_provider.dart';
import '../../core/theme/app_theme.dart';
import 'bizsquare_ribbon_painter.dart';

class AwardOnboardingScreen extends ConsumerStatefulWidget {
  const AwardOnboardingScreen({super.key});

  @override
  ConsumerState<AwardOnboardingScreen> createState() => _AwardOnboardingScreenState();
}

class _AwardOnboardingScreenState extends ConsumerState<AwardOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late AnimationController _loopCtrl;
  double _slidePage = 0.0;

  @override
  void initState() {
    super.initState();
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pageCtrl.addListener(() {
      if (mounted) {
        setState(() {
          _slidePage = _pageCtrl.page ?? _pageCtrl.initialPage.toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    final int currentPage = _slidePage.round();
    if (currentPage < 2) {
      _pageCtrl.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    } else {
      ref.read(userStateProvider.notifier).setOnboarded(true);
      context.go('/register-steps');
    }
  }

  void _onSkip() {
    ref.read(userStateProvider.notifier).setOnboarded(true);
    context.go('/auth-wall');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(userStateProvider.notifier).setOnboarded(true);
          context.go('/auth-wall');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
          // Background Perspective Grid & Ambient Gradient Glows
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loopCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PerspectiveBackgroundPainter(
                    phase: _loopCtrl.value,
                    slideProgress: _slidePage,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // Flowing BizSquare Geometric Ribbon that traverses the slides
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _loopCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: BizSquareRibbonPainter(
                      slideProgress: _slidePage,
                      wavePhase: _loopCtrl.value,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header (Logo + Skip button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            isDark
                                ? 'assets/images/bizsquare_full_white.png'
                                : 'assets/images/bizsquare_full_black.png',
                            height: 30,
                            errorBuilder: (_, __, ___) => Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.brandGradient,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.widgets_rounded, size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BizSquare',
                                  style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        child: Text(
                          'Skip',
                          style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main PageView with Top 58% Visuals and Bottom 42% Content
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    children: [
                      _buildSlide(
                        illustration: _Slide1Illustration(loopCtrl: _loopCtrl, isDark: isDark),
                        badge: 'DISCOVERY ENGINE',
                        badgeColor: AppTheme.primaryBlue,
                        title: 'Intelligent B2B\nTrade Discovery',
                        desc:
                            'Connect with verified suppliers, distributors, and buyers tailored to your specific micro-niche across Africa.',
                        isDark: isDark,
                      ),
                      _buildSlide(
                        illustration: _Slide2Illustration(loopCtrl: _loopCtrl, isDark: isDark),
                        badge: 'WHATSAPP-FIRST',
                        badgeColor: AppTheme.secondaryLime,
                        badgeTextColor: const Color(0xFF080D1A),
                        title: 'Zero Noise.\nDirect WhatsApp Deals',
                        desc:
                            'No spammy groups or endless scrolling. High-intent matches land directly on your WhatsApp every week.',
                        isDark: isDark,
                      ),
                      _buildSlide(
                        illustration: _Slide3Illustration(loopCtrl: _loopCtrl, isDark: isDark),
                        badge: 'COLLISION-FREE',
                        badgeColor: AppTheme.accentMagenta,
                        title: 'Precision Matches\n& Pocket CRM',
                        desc:
                            'Zero competitor collision. Manage leads, track customer grades, and circulate trade tokens in one seamless hub.',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Bottom Controls: Page Indicator + Primary CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      // Smooth Slide Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final double diff = (_slidePage - index).abs();
                          final double active = (1.0 - diff).clamp(0.0, 1.0);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: 6.0 + 20.0 * active,
                            decoration: BoxDecoration(
                              color: active > 0.5
                                  ? AppTheme.primaryBlue
                                  : (isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      // Primary Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _slidePage > 1.5 ? 'Get Started — Free →' : 'Continue →',
                            style: AppTheme.satoshi(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSlide({
    required Widget illustration,
    required String badge,
    required Color badgeColor,
    Color? badgeTextColor,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Column(
      children: [
        // Top 56% Illustration Zone
        Expanded(
          flex: 56,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: illustration,
            ),
          ),
        ),

        // Bottom 44% Content Zone
        Expanded(
          flex: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: isDark ? 0.20 : 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badge,
                    style: AppTheme.satoshi(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: badgeTextColor ?? badgeColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTheme.satoshi(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  desc,
                  style: AppTheme.satoshi(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// PERSPECTIVE BACKGROUND PAINTER
// ==========================================
class _PerspectiveBackgroundPainter extends CustomPainter {
  final double phase;
  final double slideProgress;
  final bool isDark;

  _PerspectiveBackgroundPainter({
    required this.phase,
    required this.slideProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glowing Ambient Orbs in Brand Colors
    final orb1 = Offset(w * 0.15 + 20 * math.sin(phase * 2 * math.pi), h * 0.25);
    final orb2 = Offset(w * 0.85 - 20 * math.cos(phase * 2 * math.pi), h * 0.40);

    canvas.drawCircle(
      orb1,
      w * 0.45,
      Paint()
        ..color = AppTheme.primaryBlue.withValues(alpha: isDark ? 0.14 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
    );

    canvas.drawCircle(
      orb2,
      w * 0.40,
      Paint()
        ..color = AppTheme.accentMagenta.withValues(alpha: isDark ? 0.10 : 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
    );
  }

  @override
  bool shouldRepaint(covariant _PerspectiveBackgroundPainter oldDelegate) => true;
}

// ==========================================
// SLIDE 1 ILLUSTRATION: DISCOVERY & RADAR
// ==========================================
class _Slide1Illustration extends StatelessWidget {
  final AnimationController loopCtrl;
  final bool isDark;

  const _Slide1Illustration({required this.loopCtrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loopCtrl,
      builder: (context, _) {
        final val = loopCtrl.value;
        final floatOffset = math.sin(val * 2 * math.pi) * 8.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Perspective Grid Platform
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(0.7)
                ..rotateZ(-0.25),
              alignment: Alignment.center,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.35),
                      AppTheme.secondaryLime.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.6), width: 2),
                ),
              ),
            ),

            // Saturated Floating SME Discovery Hub Card
            Transform.translate(
              offset: Offset(0, floatOffset),
              child: Container(
                width: 210,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryBlue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adebayo Textiles',
                                style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Lagos · Footwear & Fabrics',
                                style: AppTheme.satoshi(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryLime,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MATCH 98%',
                            style: AppTheme.satoshi(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF080D1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // High-Saturation Duotone Progress Beam
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: AppTheme.blueMagentaGradient,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orbiting Mini Node 1 (Lime)
            Positioned(
              top: 30 + floatOffset * 0.6,
              right: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryLime,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryLime.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF080D1A)),
                    const SizedBox(width: 4),
                    Text(
                      'Demand Active',
                      style: AppTheme.satoshi(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF080D1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orbiting Mini Node 2 (Magenta)
            Positioned(
              bottom: 30 - floatOffset * 0.6,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentMagenta.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Seller',
                      style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// SLIDE 2 ILLUSTRATION: AUTOMATED WHATSAPP TRADE
// ==========================================
class _Slide2Illustration extends StatelessWidget {
  final AnimationController loopCtrl;
  final bool isDark;

  const _Slide2Illustration({required this.loopCtrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loopCtrl,
      builder: (context, _) {
        final val = loopCtrl.value;
        final float = math.cos(val * 2 * math.pi) * 8.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Perspective Chat Card
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(-0.15)
                ..rotateZ(0.05),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, float),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.secondaryLime, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryLime.withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryLime,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF080D1A), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WhatsApp Match Bot',
                                  style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Automated Contact Delivery',
                                  style: AppTheme.satoshi(
                                    fontSize: 10,
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🤝 Hello! Quantum Tech Hub is seeking wholesale laptops in your territory. Tap to open chat.',
                          style: AppTheme.satoshi(
                            fontSize: 11.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Orbiting WhatsApp Direct Action Pill
            Positioned(
              bottom: 25 - float * 0.7,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '1-Click Connect',
                      style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// SLIDE 3 ILLUSTRATION: PRECISION MATCHMAKING & CRM
// ==========================================
class _Slide3Illustration extends StatelessWidget {
  final AnimationController loopCtrl;
  final bool isDark;

  const _Slide3Illustration({required this.loopCtrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loopCtrl,
      builder: (context, _) {
        final val = loopCtrl.value;
        final float = math.sin(val * 2 * math.pi) * 8.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Perspective Lead Card
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(0.12)
                ..rotateZ(-0.04),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, float),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentMagenta, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentMagenta.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentMagenta.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'POCKET CRM',
                              style: AppTheme.satoshi(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accentMagenta,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryLime,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'GRADE A+',
                              style: AppTheme.satoshi(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF080D1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: AppTheme.brandGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kemi Bio-Cosmetics',
                                  style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Warm Customer · Lagos',
                                  style: AppTheme.satoshi(
                                    fontSize: 10,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Akawo Balance',
                              style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '+10 Pts',
                              style: AppTheme.satoshi(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.secondaryLime,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
