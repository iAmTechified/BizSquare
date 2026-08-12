import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/services/biometric_service.dart';

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
    HapticFeedback.lightImpact();

    final bioService = ref.read(biometricServiceProvider);
    final authenticated = await bioService.authenticate(
      reason: 'Verify your identity to sign in to BizSquare',
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
            'Biometric verification was not completed. Please sign in with your phone and PIN.',
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058FF),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedFlash,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'BizSquare',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Network',
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

              const SizedBox(height: 28),

              // Hero Statement
              Text(
                'Grow your business\nnetwork on WhatsApp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  letterSpacing: -0.8,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gain verified contacts, manage customer relationships, and expand your reach through community Spotlight.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // 4 Core Value Pillars
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPillarRow(
                      icon: HugeIcons.strokeRoundedUserGroup,
                      title: 'Community Network',
                      desc: 'Connect with verified business owners across Nigeria.',
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildPillarRow(
                      icon: HugeIcons.strokeRoundedContact01,
                      title: 'Contact Gain',
                      desc: 'Receive new verified customer and supplier contacts weekly.',
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildPillarRow(
                      icon: HugeIcons.strokeRoundedFolder01,
                      title: 'Contact Management',
                      desc: 'Star, label, and organize your business contacts easily.',
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildPillarRow(
                      icon: HugeIcons.strokeRoundedFlash,
                      title: 'Spotlight Visibility',
                      desc: 'Your business offers broadcasted across WhatsApp status networks.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Linked Account Quick Biometric Button (if account linked)
              if (_hasLinkedAccount && linkedBusinessName != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedShieldUser,
                        color: Color(0xFF0058FF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Linked Account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0058FF),
                              ),
                            ),
                            Text(
                              linkedBusinessName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _handleBiometricLogin,
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0058FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Primary CTA: Register
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.push('/register-steps');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Create Business Account',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary CTA: Sign In
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.push('/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'I already have an account',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillarRow({
    required dynamic icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0058FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: HugeIcon(icon: icon, color: const Color(0xFF0058FF), size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
