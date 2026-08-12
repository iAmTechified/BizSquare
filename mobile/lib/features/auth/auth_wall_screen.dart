import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/widgets/bizsquare_loader.dart';

class AuthWallScreen extends ConsumerStatefulWidget {
  const AuthWallScreen({super.key});

  @override
  ConsumerState<AuthWallScreen> createState() => _AuthWallScreenState();
}

class _AuthWallScreenState extends ConsumerState<AuthWallScreen> with TickerProviderStateMixin {
  bool _hasLinkedAccount = false;
  Map<String, dynamic>? _linkedAccount;
  bool _isAuthenticating = false;

  late AnimationController _floatCtrl;
  late Animation<double> _floatOffsetAnim;
  late Animation<double> _pulseGlowAnim;

  @override
  void initState() {
    super.initState();
    _checkLinkedAccount();

    // 1. Dynamic continuous floating physics for parallax illustration accents
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatOffsetAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine),
    );

    _pulseGlowAnim = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutQuad),
    );
  }

  Future<void> _checkLinkedAccount() async {
    final bioService = ref.read(biometricServiceProvider);
    final hasLinked = await bioService.hasLinkedAccount();
    if (hasLinked) {
      final account = await bioService.getLinkedAccount();
      if (mounted) {
        setState(() {
          _hasLinkedAccount = true;
          _linkedAccount = account;
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_linkedAccount == null || _isAuthenticating) return;

    setState(() => _isAuthenticating = true);
    HapticFeedback.mediumImpact();

    final bioService = ref.read(biometricServiceProvider);
    final authenticated = await bioService.authenticate(
      reason: 'Confirm identity to open your business account',
    );

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (authenticated) {
      final token = _linkedAccount!['token'] as String;
      final user = _linkedAccount!['user'] as Map<String, dynamic>;

      ref.read(userStateProvider.notifier).login(
            token: token,
            user: user,
          );

      context.go('/daily-wall');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric sign-in missed. You can sign in with your PIN.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final linkedUser = (_linkedAccount?['user'] as Map<String, dynamic>?) ?? {};
    final linkedBusinessName = linkedUser['business_name'] as String? ??
        linkedUser['full_name'] as String? ??
        _linkedAccount?['phoneNumber'] as String?;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Cinematic Ambient Glow Mesh Background
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (context, child) {
              return Positioned.fill(
                child: Stack(
                  children: [
                    Positioned(
                      top: -100,
                      left: -80,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0058FF).withValues(alpha: _pulseGlowAnim.value),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 180,
                      right: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: _pulseGlowAnim.value * 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Main Non-Scrolling Viewport
          SafeArea(
            child: Column(
              children: [
                // Top Header (Logo Freely Standing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      isDark
                          ? 'assets/images/bizsquare_full_white.png'
                          : 'assets/images/bizsquare_full_black.png',
                      height: 34,
                      errorBuilder: (_, __, ___) => Row(
                        children: [
                          Image.asset('assets/images/bizsquare_icon.png', height: 32),
                          const SizedBox(width: 8),
                          Text(
                            'BizSquare',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Headline & Subtitle Text (Centered on Business Growth)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Everything Your Business\nNeeds to Grow & Sell More',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connect with direct buyers, showcase your products, and manage customer relationships effortlessly.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Cinematic Full-Bleed 2D Editorial Hero Artwork Stage (NO CARD, NO BOX)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _floatOffsetAnim,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Main 2D Editorial Artwork Image (Freely Standing, Seamless Integration)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Transform.translate(
                                offset: Offset(0, _floatOffsetAnim.value * 0.4),
                                child: Image.asset(
                                  'assets/images/bizsquare_hero_art.jpg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/auth_hero_illustration.jpg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Floating Dynamic Accent Pill 1: Top Right (Parallax Float)
                          Positioned(
                            top: 20 + _floatOffsetAnim.value,
                            right: 28,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161E2E).withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedContact01,
                                    color: Color(0xFF10B981),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Direct Customer Gain',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Floating Dynamic Accent Pill 2: Bottom Left (Parallax Float Reverse)
                          Positioned(
                            bottom: 24 - _floatOffsetAnim.value,
                            left: 28,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161E2E).withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF0058FF).withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0058FF).withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedFlash,
                                    color: Color(0xFF0058FF),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Spotlight Broadcast',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0058FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 4. Fixed Bottom Action Glassmorphic Panel (Always Pinned to Bottom, Zero Scroll)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A0E1A).withValues(alpha: 0.95)
                        : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Biometric Quick Sign-In Bar (If Linked Account Exists)
                      if (_hasLinkedAccount && linkedBusinessName != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0058FF).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedLockKey,
                                color: Color(0xFF0058FF),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  linkedBusinessName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: _isAuthenticating ? null : _handleBiometricLogin,
                                child: _isAuthenticating
                                    ? const BizSquareLoader(size: 16)
                                    : Text(
                                        'Quick Sign In',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0058FF),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Primary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.push('/register-steps');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0058FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get Started — Create Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/login');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Sign In to Your Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
    );
  }
}
