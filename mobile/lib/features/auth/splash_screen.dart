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

  // Gradient text controller
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

    // 3. Continuous Gradient Sweep Controller
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
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
            const Spacer(),
            
            // Main Center Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo Area: Unboxed, Larger
                ScaleTransition(
                  scale: _logoScaleAnim,
                  child: Image.asset(
                    'assets/images/bizsquare_icon.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/bizsquare_icon_nobg.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Sequential Flag-Up Entrance: BizSquare Name Text
                SlideTransition(
                  position: _titleSlideAnim,
                  child: FadeTransition(
                    opacity: _titleFadeAnim,
                    child: Text(
                      'BizSquare',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 40, 
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),

                // Custom Branded BizSquare Animated Loader
                const BizSquareLoader(size: 32),
              ],
            ),
            
            const Spacer(),

            // 3. Sequential Flag-Up Entrance: Tagline "Grow Together" at the bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: SlideTransition(
                position: _taglineSlideAnim,
                child: FadeTransition(
                  opacity: _taglineFadeAnim,
                  child: AnimatedBuilder(
                    animation: _loopCtrl,
                    builder: (context, child) {
                      final progress = _loopCtrl.value;
                      return ShaderMask(
                        blendMode: BlendMode.srcIn, 
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
                            fontWeight: FontWeight.w200, 
                            letterSpacing: 3.5, 
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _GradientRotation extends GradientTransform {
  final double radians;
  const _GradientRotation(this.radians);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    return Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(center.dx, center.dy)
      ..rotateZ(radians)
      // ignore: deprecated_member_use
      ..translate(-center.dx, -center.dy);
  }
}
