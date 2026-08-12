import 'dart:math' as math;
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
  late Animation<double> _logoScaleAnim;
  late Animation<double> _titleFadeAnim;
  late Animation<Offset> _titleSlideAnim;
  late Animation<double> _taglineFadeAnim;
  late Animation<Offset> _taglineSlideAnim;

  // Expanding aura glow behind logo
  late AnimationController _auraGlowCtrl;
  late Animation<double> _auraScaleAnim;
  late Animation<double> _auraOpacityAnim;

  // Perimeter 4-edge laser line & gradient text controller
  late AnimationController _loopCtrl;

  @override
  void initState() {
    super.initState();

    // 1. Staggered Flag-Up Entrance Controller (1.4s)
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScaleAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );

    // Title Entrance (Interval 0.25 -> 0.70)
    _titleFadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.70, curve: Curves.easeIn),
    );
    _titleSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.70, curve: Curves.easeOutCubic),
    ));

    // Tagline Entrance (Interval 0.50 -> 0.95 - Flag up follow-through)
    _taglineFadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.50, 0.95, curve: Curves.easeIn),
    );
    _taglineSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.40),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.50, 0.95, curve: Curves.easeOutCubic),
    ));

    _entranceCtrl.forward();

    // 2. Expanding Aura Glow Controller
    _auraGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _auraScaleAnim = Tween<double>(begin: 0.9, end: 2.2).animate(
      CurvedAnimation(parent: _auraGlowCtrl, curve: Curves.easeOutCubic),
    );
    _auraOpacityAnim = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _auraGlowCtrl, curve: Curves.easeOutQuad),
    );

    // 3. Continuous 4-Edge Laser & Gradient Sweep Controller
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
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
    _loopCtrl.dispose();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Logo Area: Unboxed, Larger (96x96), Original Colors Maintained
              ScaleTransition(
                scale: _logoScaleAnim,
                child: SizedBox(
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
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  color: const Color(0xFF0058FF).withValues(alpha: isDark ? 0.35 : 0.20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.30 : 0.15),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 4 Moving Edge Laser Lines around the Square Perimeter
                      AnimatedBuilder(
                        animation: _loopCtrl,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(108, 108),
                            painter: _SquarePerimeterLaserPainter(
                              progress: _loopCtrl.value,
                              isDark: isDark,
                            ),
                          );
                        },
                      ),

                      // Real Original Logo Image (Original Colors Preserved, No Shader Masking)
                      Image.asset(
                        'assets/images/bizsquare_icon.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/bizsquare_icon_nobg.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Sequential Flag-Up Entrance: BizSquare Name Text (Logo is 96px, Name is 26px so logo is larger!)
              SlideTransition(
                position: _titleSlideAnim,
                child: FadeTransition(
                  opacity: _titleFadeAnim,
                  child: Text(
                    'BizSquare',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26, // Smaller than 96px logo
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 3. Sequential Flag-Up Entrance: Tagline "Grow Together" (Thin Font Weight & Animated Gradient Text)
              SlideTransition(
                position: _taglineSlideAnim,
                child: FadeTransition(
                  opacity: _taglineFadeAnim,
                  child: AnimatedBuilder(
                    animation: _loopCtrl,
                    builder: (context, child) {
                      final progress = _loopCtrl.value;
                      return ShaderMask(
                        blendMode: BlendMode.srcIn, // Text color IS the gradient
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            transform: _GradientRotation(progress * 2 * math.pi),
                            colors: const [
                              Color(0xFF0058FF),
                              Color(0xFF10B981),
                              Color(0xFF7C3AED),
                              Color(0xFF0058FF),
                            ],
                            stops: const [0.0, 0.35, 0.70, 1.0],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'Grow Together',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w200, // THIN FONT WEIGHT
                            letterSpacing: 3.5, // ELEGANT & SPACIOUS
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // 4. Custom Branded BizSquare Animated Loader
              const BizSquareLoader(size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for 4 Moving Edge Laser Lines around the Square Logo Perimeter
class _SquarePerimeterLaserPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _SquarePerimeterLaserPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(28),
    );

    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;

    // 4 Edge Segments traveling seamlessly along the square perimeter with zero gaps
    const segmentCount = 4;
    final segmentLength = totalLength / segmentCount;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final colors = [
      const Color(0xFF0058FF),
      const Color(0xFF10B981),
      const Color(0xFF7C3AED),
      const Color(0xFFF59E0B),
    ];

    for (int i = 0; i < segmentCount; i++) {
      final start = ((progress * totalLength) + (i * segmentLength)) % totalLength;
      final end = (start + (segmentLength * 0.45)) % totalLength;

      paint.color = colors[i % colors.length];

      if (start < end) {
        final extractPath = pathMetrics.extractPath(start, end);
        canvas.drawPath(extractPath, paint);
      } else {
        final extractPath1 = pathMetrics.extractPath(start, totalLength);
        final extractPath2 = pathMetrics.extractPath(0, end);
        canvas.drawPath(extractPath1, paint);
        canvas.drawPath(extractPath2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SquarePerimeterLaserPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

class _GradientRotation extends GradientTransform {
  final double radians;
  const _GradientRotation(this.radians);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    final m = Matrix4.identity();
    m.translateByDouble(center.dx, center.dy, 0.0);
    m.rotateZ(radians);
    m.translateByDouble(-center.dx, -center.dy, 0.0);
    return m;
  }
}
