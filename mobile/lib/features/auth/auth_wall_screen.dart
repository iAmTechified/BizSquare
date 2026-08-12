import 'dart:async';
import 'dart:ui';
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

class _AuthWallScreenState extends ConsumerState<AuthWallScreen> with SingleTickerProviderStateMixin {
  bool _hasLinkedAccount = false;
  Map<String, dynamic>? _linkedAccount;
  bool _isAuthenticating = false;

  late PageController _pageController;
  int _activeHeroPage = 0;
  Timer? _carouselTimer;

  late AnimationController _ambientGlowController;

  final List<_HeroFeatureCardData> _heroFeatures = const [
    _HeroFeatureCardData(
      title: 'Weekly Contact Gain',
      headline: 'Expand your WhatsApp reach by 10+ verified contacts every week.',
      badgeText: 'AUTOMATED MATCHING',
      accentColor: Color(0xFF10B981),
      icon: HugeIcons.strokeRoundedContact01,
      previewWidget: _ContactGainHeroGraphic(),
    ),
    _HeroFeatureCardData(
      title: 'Spotlight Broadcast',
      headline: 'Broadcast your business offers across thousands of WhatsApp Statuses.',
      badgeText: 'NETWORK VIRALITY',
      accentColor: Color(0xFF0058FF),
      icon: HugeIcons.strokeRoundedFlash,
      previewWidget: _SpotlightHeroGraphic(),
    ),
    _HeroFeatureCardData(
      title: 'Pocket CRM & Pipeline',
      headline: 'Organize customers with grades, custom labels, and instant WhatsApp chat.',
      badgeText: 'LEAD MANAGEMENT',
      accentColor: Color(0xFF7C3AED),
      icon: HugeIcons.strokeRoundedFolder01,
      previewWidget: _CrmHeroGraphic(),
    ),
    _HeroFeatureCardData(
      title: 'Verified Business Network',
      headline: 'Connect with active suppliers, buyers, and service providers across Nigeria.',
      badgeText: '100% VERIFIED',
      accentColor: Color(0xFFF59E0B),
      icon: HugeIcons.strokeRoundedUserGroup,
      previewWidget: _NetworkHeroGraphic(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _checkLinkedAccount();

    _ambientGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startCarouselAutoPlay();
  }

  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_activeHeroPage + 1) % _heroFeatures.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.fastOutSlowIn,
      );
    });
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
      reason: 'Verify identity to sign in to BizSquare',
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
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _ambientGlowController.dispose();
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
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Ambient Dynamic Glow Backdrop (Awwwards Visual Mesh)
          AnimatedBuilder(
            animation: _ambientGlowController,
            builder: (context, child) {
              final value = _ambientGlowController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + (value * 20),
                    right: -40 + (value * 30),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0058FF).withValues(alpha: isDark ? 0.22 : 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 120 - (value * 20),
                    left: -60 + (value * 20),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.10),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Main Content Viewport
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Top Header: Logo + Live Verified Pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '2,400+ Verified Network',
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
                ),

                const SizedBox(height: 20),

                // Headline Statement
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Business Growth, Automated.',
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
                          'Join Nigeria\'s largest verified business network.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Awwwards Showcase Hero Feature Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _heroFeatures.length,
                    onPageChanged: (idx) {
                      setState(() => _activeHeroPage = idx);
                    },
                    itemBuilder: (context, idx) {
                      final item = _heroFeatures[idx];
                      return _buildHeroShowcaseCard(item, isDark);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Page Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_heroFeatures.length, (idx) {
                    final isActive = idx == _activeHeroPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF0058FF)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // 4. Linked Biometric Login Card (If Account Exists)
                if (_hasLinkedAccount && linkedBusinessName != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131C31).withValues(alpha: 0.9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF0058FF).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                              icon: HugeIcons.strokeRoundedShieldKey,
                              color: Color(0xFF0058FF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LINKED BUSINESS ACCOUNT',
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  ),
                ],

                // 5. Dual CTAs (Signature Tactile Buttons)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Primary Button: Register
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
                            shadowColor: const Color(0xFF0058FF).withValues(alpha: 0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Business Account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowRight01,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Button: Sign In
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
                            'I already have an account',
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

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHOWCASE CARD BUILDER
  // ==========================================
  Widget _buildHeroShowcaseCard(_HeroFeatureCardData data, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31).withValues(alpha: 0.95) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: data.accentColor.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: data.accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Category Pill & Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: data.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: data.accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: data.icon,
                  color: data.accentColor,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            data.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.headline,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),

          const Spacer(),

          // Graphic Illustration Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: data.previewWidget,
          ),
        ],
      ),
    );
  }
}

class _HeroFeatureCardData {
  final String title;
  final String headline;
  final String badgeText;
  final Color accentColor;
  final dynamic icon;
  final Widget previewWidget;

  const _HeroFeatureCardData({
    required this.title,
    required this.headline,
    required this.badgeText,
    required this.accentColor,
    required this.icon,
    required this.previewWidget,
  });
}

// ==========================================
// AWWWARDS HERO GRAPHIC MOCKUPS
// ==========================================

class _ContactGainHeroGraphic extends StatelessWidget {
  const _ContactGainHeroGraphic();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedContact01,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '+10 Verified Contacts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Weekly Batch',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildAvatarChip('Adebayo Electronics', 'Phones & Solar'),
            const SizedBox(width: 8),
            _buildAvatarChip('Chioma Fashion', 'Wholesale Fabrics'),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarChip(String name, String tag) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              tag,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightHeroGraphic extends StatelessWidget {
  const _SpotlightHeroGraphic();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0058FF).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedFlash,
              color: Color(0xFF0058FF),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spotlight Status Campaign',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '1,420 Network Views • 18 Partitions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: const Color(0xFF0058FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
      ],
    );
  }
}

class _CrmHeroGraphic extends StatelessWidget {
  const _CrmHeroGraphic();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTagPill('Grade A Lead', const Color(0xFF10B981)),
        _buildTagPill('VIP Buyer', const Color(0xFF7C3AED)),
        _buildTagPill('Supplier', const Color(0xFF0058FF)),
      ],
    );
  }

  Widget _buildTagPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _NetworkHeroGraphic extends StatelessWidget {
  const _NetworkHeroGraphic();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
          color: Color(0xFFF59E0B),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '100% Verified Business Identities via WhatsApp OTP',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
    );
  }
}
