import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/spotlight_model.dart';
import '../../core/providers/spotlight_state_provider.dart';
import 'widgets/spotlight_card.dart';

class SpotlightScreen extends ConsumerStatefulWidget {
  const SpotlightScreen({super.key});

  @override
  ConsumerState<SpotlightScreen> createState() => _SpotlightScreenState();
}

class _SpotlightScreenState extends ConsumerState<SpotlightScreen> {
  final _titleController = TextEditingController();
  final _promoController = TextEditingController();
  final _captionController = TextEditingController();

  bool _showPreview = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    // Load draft if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(spotlightStateProvider).draft;
      if (draft != null) {
        _titleController.text = draft.title;
        _promoController.text = draft.promoText;
        _captionController.text = draft.caption;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promoController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    ref.read(spotlightStateProvider.notifier).saveDraft(
          title: _titleController.text,
          promoText: _promoController.text,
          caption: _captionController.text,
        );
    if (mounted) setState(() {});
  }

  Future<void> _shareActiveSpotlight() async {
    final state = ref.read(spotlightStateProvider);
    final spotlight = state.spotlight;
    if (spotlight == null) return;

    setState(() => _isSharing = true);
    try {
      final text = '${spotlight.content?.promoText ?? "Check out our featured verified partner on BizSquare!"}\n\n${spotlight.content?.caption ?? "#GrowTogether #BizSquare"}';
      await Share.share(text, subject: spotlight.content?.title ?? 'BizSquare Spotlight');
      await ref.read(spotlightStateProvider.notifier).participateInCurrentSpotlight();
    } catch (_) {}
    if (mounted) setState(() => _isSharing = false);
  }

  Future<void> _handleSubmitSpotlight() async {
    final title = _titleController.text.trim();
    final promo = _promoController.text.trim();
    final caption = _captionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for your Spotlight.')),
      );
      return;
    }
    if (promo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what you are offering.')),
      );
      return;
    }

    final success = await ref.read(spotlightStateProvider.notifier).submitSpotlight(
          title: title,
          promoText: promo,
          caption: caption.isEmpty ? '#BizSquare #VerifiedPartner' : caption,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Spotlight submitted! Verification in progress.'),
          ),
        );
        setState(() {
          _showPreview = false;
        });
      } else {
        final err = ref.read(spotlightStateProvider).errorMessage ?? 'Failed to submit Spotlight.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(err),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spotlightStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spotlight',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Your weekly visibility',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => context.push('/spotlight/history'),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: Color(0xFF0058FF),
                size: 18,
              ),
              label: Text(
                'History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0058FF),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: const Color(0xFF0058FF).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(spotlightStateProvider.notifier).refresh(),
        color: const Color(0xFF0058FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Offline Banner
              if (state.isOffline) _buildOfflineBanner(isDark),

              // 2. Loading State (Shimmer Skeleton)
              if (state.isLoading && state.spotlight == null)
                _buildLoadingSkeleton(isDark)
              // 3. Error State
              else if (state.errorMessage != null && state.spotlight == null)
                _buildErrorState(state.errorMessage!, isDark)
              // 4. Main Spotlight Content
              else if (state.spotlight != null) ...[
                if (state.spotlight!.isMyTurn)
                  _buildMyTurnExperience(state, isDark)
                else
                  _buildNotMyTurnExperience(state, isDark),
              ],

              const SizedBox(height: 24),
              _buildHowItWorksCard(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedWifi01,
            color: Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline. Showing latest cached Spotlight.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            color: Color(0xFFEF4444),
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            "Couldn't load Spotlight",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => ref.read(spotlightStateProvider.notifier).loadSpotlight(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0058FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MY TURN EXPERIENCE
  // ==========================================
  Widget _buildMyTurnExperience(SpotlightState state, bool isDark) {
    final spotlight = state.spotlight!;
    final req = spotlight.requirement;
    final isPendingOrVerified = spotlight.submissionStatus == SpotlightSubmissionStatus.pending ||
        spotlight.submissionStatus == SpotlightSubmissionStatus.verified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Action Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0058FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0058FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFlash,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR TURN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0058FF),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "It's time to share your Spotlight",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your submission will be shared across ${spotlight.targetParticipants} verified business partners.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // If already submitted and verified / pending, display the active Spotlight card
        if (isPendingOrVerified && !_showPreview && spotlight.content?.title != null) ...[
          SpotlightCard(
            spotlight: spotlight,
            variant: SpotlightCardVariant.mine,
            onEdit: () {
              setState(() {
                _titleController.text = spotlight.content?.title ?? '';
                _promoController.text = spotlight.content?.promoText ?? '';
                _captionController.text = spotlight.content?.caption ?? '';
                _showPreview = false;
              });
            },
          ),
        ] else ...[
          // Submission Form & Dynamic Requirement
          _buildSubmissionForm(req, state, isDark),
        ],
      ],
    );
  }

  Widget _buildSubmissionForm(SpotlightRequirementModel req, SpotlightState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt Header
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedMegaphone01,
                color: Color(0xFF0058FF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'What are you sharing?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            req.prompt,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (state.draft != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedBookmark02,
                  color: Color(0xFF10B981),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Draft saved locally',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Title Field
          Text(
            'Spotlight Headline',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            onChanged: (_) => _onFormChanged(),
            maxLength: 60,
            decoration: InputDecoration(
              hintText: 'e.g. 20% Discount on Wears This Week',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Promo Description
          Text(
            'Offer Details & Value',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _promoController,
            onChanged: (_) => _onFormChanged(),
            maxLines: 4,
            maxLength: req.maxCharacters,
            decoration: InputDecoration(
              hintText: req.placeholder,
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // WhatsApp Caption
          Text(
            'WhatsApp Status Caption / Hashtags',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _captionController,
            onChanged: (_) => _onFormChanged(),
            maxLength: 100,
            decoration: InputDecoration(
              hintText: '#BizSquare #VerifiedPartner #SpecialOffer',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preview Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Preview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              Switch.adaptive(
                value: _showPreview,
                onChanged: (val) => setState(() => _showPreview = val),
                activeTrackColor: const Color(0xFF0058FF),
              ),
            ],
          ),

          if (_showPreview) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleController.text.isEmpty ? 'Your Spotlight Headline' : _titleController.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _promoController.text.isEmpty
                        ? 'Your offer description will appear here...'
                        : _promoController.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _captionController.text.isEmpty ? '#BizSquare #Partner' : _captionController.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0058FF),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Primary Submit CTA
          ElevatedButton.icon(
            onPressed: state.isSubmitting ? null : _handleSubmitSpotlight,
            icon: state.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: Colors.white,
                    size: 18,
                  ),
            label: Text(
              state.isSubmitting ? 'Submitting Spotlight...' : 'Submit Spotlight',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0058FF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NOT MY TURN EXPERIENCE
  // ==========================================
  Widget _buildNotMyTurnExperience(SpotlightState state, bool isDark) {
    final spotlight = state.spotlight!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Status Information Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTime04,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOT YOUR TURN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "You're waiting for your Spotlight turn",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share current partner spotlights on WhatsApp to earn Akawo points for your upcoming turn.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Active Featured Community Spotlight Card
        SpotlightCard(
          spotlight: spotlight,
          variant: SpotlightCardVariant.feed,
          onShare: _shareActiveSpotlight,
          isSharing: _isSharing,
        ),
      ],
    );
  }

  Widget _buildHowItWorksCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How Spotlight Visibility Works',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildExplainerRow(
                icon: HugeIcons.strokeRoundedShare01,
                title: '1. Community WhatsApp Sharing',
                desc: 'Verified network partners share active partner spotlights directly on WhatsApp Status.',
                isDark: isDark,
              ),
              const Divider(height: 24),
              _buildExplainerRow(
                icon: HugeIcons.strokeRoundedCoins01,
                title: '2. Earn Akawo Points',
                desc: 'Sharing daily partner spotlights earns you +2 Akawo points, improving your priority in Contact Gain matching.',
                isDark: isDark,
              ),
              const Divider(height: 24),
              _buildExplainerRow(
                icon: HugeIcons.strokeRoundedFlash,
                title: "3. Your Spotlight Turn",
                desc: 'When it is your turn, your verified business offer is submitted and broadcasted across dozens of business networks.',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExplainerRow({
    required dynamic icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0058FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: HugeIcon(icon: icon, color: const Color(0xFF0058FF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
