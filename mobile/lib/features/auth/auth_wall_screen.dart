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

class _AuthWallScreenState extends ConsumerState<AuthWallScreen> {
  bool _hasLinkedAccount = false;
  Map<String, dynamic>? _linkedAccount;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkLinkedAccount();
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final linkedUser = (_linkedAccount?['user'] as Map<String, dynamic>?) ?? {};
    final linkedBusinessName = linkedUser['business_name'] as String? ??
        linkedUser['full_name'] as String? ??
        _linkedAccount?['phoneNumber'] as String?;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // 1. Top Logo Header
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  isDark
                      ? 'assets/images/bizsquare_full_white.png'
                      : 'assets/images/bizsquare_full_black.png',
                  height: 32,
                  errorBuilder: (_, __, ___) => Row(
                    children: [
                      Image.asset('assets/images/bizsquare_icon.png', height: 30),
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

              const SizedBox(height: 20),

              // 2. Headline & Subtitle (Focused on Business Growth)
              Align(
                alignment: Alignment.centerLeft,
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
                    const SizedBox(height: 8),
                    Text(
                      'Connect with direct buyers, showcase your products, and manage customer relationships effortlessly.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Central Hero Graphic / Subject Container (Non-scrolling, easy to replace asset later)
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 360, maxHeight: 300),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C31) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0058FF).withValues(alpha: isDark ? 0.2 : 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Central Graphic Avatar/Badge Illustration
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                            border: Border.all(
                              color: const Color(0xFF0058FF).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedStore01,
                              color: Color(0xFF0058FF),
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Your Business Hub',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Buyers • Sales • Product Visibility',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0058FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Fixed Bottom Section (Never Scrolls, Pinned to Bottom)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Biometric Quick Sign-In (If Linked Account Exists)
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
            ],
          ),
        ),
      ),
    );
  }
}
