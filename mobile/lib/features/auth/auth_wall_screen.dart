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
      reason: 'Verify identity to open your business account',
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
            'Authentication missed. You can sign in with your PIN.',
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
      body: Stack(
        children: [
          // Ambient Glow Accent
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0058FF).withValues(alpha: isDark ? 0.18 : 0.08),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Top Header: Logo Asset & Verified Community Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Business Community',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Main Benefit Headline
                  Text(
                    'Turn your WhatsApp into your biggest sales channel.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Get introduced to genuine buyers, expand your product reach on Status, and build direct business relationships.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3 High-Impact Benefit Cards (No gimmicky carousel, clean static visual layout)
                  _buildBenefitCard(
                    isDark: isDark,
                    accentColor: const Color(0xFF10B981),
                    icon: HugeIcons.strokeRoundedContact01,
                    tagline: 'GET NEW CUSTOMERS',
                    title: 'Fresh Buyer & Supplier Contacts',
                    description: 'Get introduced to verified business owners and serious buyers looking directly for what you sell.',
                  ),
                  const SizedBox(height: 14),

                  _buildBenefitCard(
                    isDark: isDark,
                    accentColor: const Color(0xFF0058FF),
                    icon: HugeIcons.strokeRoundedFlash,
                    tagline: 'MAXIMIZE VISIBILITY',
                    title: 'Community Spotlight Broadcast',
                    description: 'Get your products featured on active WhatsApp Statuses across your business community with one tap.',
                  ),
                  const SizedBox(height: 14),

                  _buildBenefitCard(
                    isDark: isDark,
                    accentColor: const Color(0xFF7C3AED),
                    icon: HugeIcons.strokeRoundedFolder01,
                    tagline: 'CLOSE MORE DEALS',
                    title: 'Smart Customer Relationship Book',
                    description: 'Organize your leads, track top customers, and initiate instant chats directly from one dashboard.',
                  ),

                  const SizedBox(height: 28),

                  // Linked Biometric Quick Sign-In (If previous account linked)
                  if (_hasLinkedAccount && linkedBusinessName != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0058FF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedLockKey,
                              color: Color(0xFF0058FF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME BACK',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0058FF),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  linkedBusinessName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isAuthenticating ? null : _handleBiometricLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0058FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isAuthenticating
                                ? const BizSquareLoader(size: 16)
                                : Text(
                                    'Quick Sign In',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Buttons
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Create Free Business Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required bool isDark,
    required Color accentColor,
    required dynamic icon,
    required String tagline,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: HugeIcon(
              icon: icon,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tagline,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
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
