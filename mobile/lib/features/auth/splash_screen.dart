import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/widgets/bizsquare_loader.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Expanding aura glow behind logo
  late AnimationController _auraGlowCtrl;
  late Animation<double> _auraScaleAnim;
  late Animation<double> _auraOpacityAnim;

  // Shimmer / Gradient animation over logo & text
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Controller
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn);
    _scaleAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack);
    _entranceCtrl.forward();

    // 2. Expanding Aura Glow Controller (Repeats: expands out while fading out)
    _auraGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _auraScaleAnim = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _auraGlowCtrl, curve: Curves.easeOutCubic),
    );
    _auraOpacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _auraGlowCtrl, curve: Curves.easeOutQuad),
    );

    // 3. Continuous Shimmer Sweep Controller
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // Hydrate persistent state from secure storage
    await ref.read(userStateProvider.notifier).initFromStorage();

    // Enforce 5-second splash duration
    final elapsed = DateTime.now().difference(startTime);
    const targetDelay = Duration(milliseconds: 5000);
    if (elapsed < targetDelay) {
      await Future.delayed(targetDelay - elapsed);
    }

    if (!mounted) return;
    final userState = ref.read(userStateProvider);

    if (userState.isAuthenticated) {
      if (!userState.onboardingCompleted) {
        context.go('/register-steps');
      } else if (userState.completedDailyWallToday) {
        context.go('/home');
      } else {
        context.go('/daily-wall');
      }
    } else {
      if (userState.hasOnboarded) {
        context.go('/auth-wall');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _auraGlowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Logo Area (NO CARD CONTAINER / NO CARD BOX)
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding & Fading Background Glow Aura
                        AnimatedBuilder(
                          animation: _auraGlowCtrl,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _auraScaleAnim.value,
                              child: Opacity(
                                opacity: _auraOpacityAnim.value,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0058FF).withValues(alpha: isDark ? 0.45 : 0.25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.2),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Animated Glowing Edge Ring Line
                        AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (context, child) {
                            final angle = _shimmerCtrl.value * 2 * 3.14159265;
                            return Container(
                              width: 94,
                              height: 94,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  transform: GradientRotation(angle),
                                  colors: const [
                                    Color(0xFF0058FF),
                                    Color(0xFF10B981),
                                    Color(0xFF7C3AED),
                                    Color(0xFF0058FF),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.scaffoldBackgroundColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Raw Unboxed Logo Image with Shimmer Sweep Overlay
                        AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (context, child) {
                            return ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (bounds) {
                                final shimmerPos = _shimmerCtrl.value * bounds.width * 2 - bounds.width;
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: const [
                                    Colors.white,
                                    Color(0xFFE2E8F0),
                                    Colors.white,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  transform: GradientTranslation(Offset(shimmerPos, 0)),
                                ).createShader(bounds);
                              },
                              child: Image.asset(
                                'assets/images/bizsquare_icon.png',
                                width: 72,
                                height: 72,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/bizsquare_icon_nobg.png',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Animated BizSquare Text with Subtle Gradient Sweep
                  AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (context, child) {
                      final shimmerPos = _shimmerCtrl.value * 2 - 0.5;
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: isDark
                                ? const [
                                    Color(0xFFF8FAFC),
                                    Color(0xFF60A5FA),
                                    Color(0xFF34D399),
                                    Color(0xFFF8FAFC),
                                  ]
                                : const [
                                    Color(0xFF0F172A),
                                    Color(0xFF0058FF),
                                    Color(0xFF10B981),
                                    Color(0xFF0F172A),
                                  ],
                            stops: const [0.0, 0.45, 0.55, 1.0],
                            transform: GradientTranslation(Offset(shimmerPos * bounds.width, 0)),
                          ).createShader(bounds);
                        },
                        child: Text(
                          'BizSquare',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // 3. Tagline: "Grow Together" (Thin Font Weight & Animated Gradient Shimmer)
                  AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (context, child) {
                      final shimmerPos = (_shimmerCtrl.value + 0.3) % 1.0;
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: isDark
                                ? const [
                                    Color(0xFF94A3B8),
                                    Color(0xFFF1F5F9),
                                    Color(0xFF94A3B8),
                                  ]
                                : const [
                                    Color(0xFF64748B),
                                    Color(0xFF0F172A),
                                    Color(0xFF64748B),
                                  ],
                            stops: const [0.0, 0.5, 1.0],
                            transform: GradientTranslation(Offset((shimmerPos * 2 - 1) * bounds.width, 0)),
                          ).createShader(bounds);
                        },
                        child: Text(
                          'Grow Together',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w200, // THIN FONT WEIGHT AS REQUESTED
                            letterSpacing: 4.0, // SPACIOUS & ELEGANT
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // 4. Custom Branded BizSquare Animated Loader
                  const BizSquareLoader(size: 34),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientTranslation extends GradientTransform {
  final Offset offset;
  const GradientTranslation(this.offset);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(offset.dx, offset.dy, 0);
  }
}
