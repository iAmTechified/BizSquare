import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/wall_content_model.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/services/interest_service.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'widgets/multi_format_card_renderers.dart';

class DailyInteractiveWallScreen extends ConsumerStatefulWidget {
  const DailyInteractiveWallScreen({super.key});

  @override
  ConsumerState<DailyInteractiveWallScreen> createState() => _DailyInteractiveWallScreenState();
}

class _DailyInteractiveWallScreenState extends ConsumerState<DailyInteractiveWallScreen> {
  int _cardIndex = 0;
  bool _isLoading = true;
  String? _sessionId;
  List<WallSessionItemModel> _items = [];
  DateTime _cardStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDailySession();
  }

  Future<void> _loadDailySession() async {
    final interestService = ref.read(interestServiceProvider);
    final session = await interestService.fetchDailyWallSession(targetCount: 5);

    if (mounted) {
      if (session != null && session.items.isNotEmpty) {
        setState(() {
          _sessionId = session.sessionId;
          _items = session.items;
          _isLoading = false;
          _cardStartTime = DateTime.now();
        });
      } else {
        setState(() {
          _sessionId = null;
          _items = _getFallbackItems();
          _isLoading = false;
          _cardStartTime = DateTime.now();
        });
      }
    }
  }

  List<WallSessionItemModel> _getFallbackItems() {
    return [
      WallSessionItemModel(
        contentId: 'fallback_1',
        format: 'THIS_OR_THAT',
        titlePrompt: 'Which business capability would you upgrade first right now?',
        description: 'Reveals priority between direct customer outreach and inventory workstation infrastructure.',
        contextType: 'general',
        poolType: 'PERSONALIZED',
        orderIndex: 1,
        options: [
          ContentOptionModel(
            optionKey: 'opt_a',
            label: 'Mobile WhatsApp Commerce Hub',
            subtext: 'High-speed customer lead processing and catalog broadcast',
          ),
          ContentOptionModel(
            optionKey: 'opt_b',
            label: 'Business Fulfillment & Operations',
            subtext: 'Inventory management and delivery logistics speed',
          ),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_2',
        format: 'WOULD_YOU',
        titlePrompt: 'Would you test same-day dispatch partnerships with verified local riders?',
        description: 'Testing delivery efficiency readiness and order fulfillment preferences.',
        contextType: 'business',
        poolType: 'RELATED',
        orderIndex: 2,
        options: [
          ContentOptionModel(
            optionKey: 'yes',
            label: 'Yes, Absolutely',
            subtext: 'Need faster fulfillment for customer satisfaction',
          ),
          ContentOptionModel(
            optionKey: 'maybe',
            label: 'Interested to Learn More',
            subtext: 'Would compare pricing and coverage rates',
          ),
          ContentOptionModel(
            optionKey: 'no',
            label: 'Not Right Now',
            subtext: 'Existing logistics arrangement is sufficient',
          ),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_3',
        format: 'SCENARIO',
        titlePrompt: 'You secure a ₦200,000 seasonal expansion fund. Where does it create the highest ROI?',
        description: 'Pinpoints commercial focus areas for your upcoming trade matches.',
        contextType: 'business',
        poolType: 'EXPLORATION',
        orderIndex: 3,
        options: [
          ContentOptionModel(
            optionKey: 'opt_ads',
            label: 'Direct Lead Acquisition',
            subtext: 'Targeted customer outreach and promotion',
          ),
          ContentOptionModel(
            optionKey: 'opt_dispatch',
            label: 'Inventory Stocking',
            subtext: 'Bulk purchase top-selling merchandise',
          ),
          ContentOptionModel(
            optionKey: 'opt_brand',
            label: 'Packaging & Premium Branding',
            subtext: 'Elevate unboxing and customer retention',
          ),
          ContentOptionModel(
            optionKey: 'opt_solar',
            label: 'Power & Operational Stability',
            subtext: 'Ensure seamless 24/7 business uptime',
          ),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_4',
        format: 'REACTION_CARD',
        titlePrompt: 'Weekly Partner Spotlight Exchange on WhatsApp Status',
        description: 'Testing willingness to exchange visibility with other verified business owners.',
        contextType: 'emerging',
        poolType: 'BROAD',
        orderIndex: 4,
        options: [
          ContentOptionModel(optionKey: 'react_love', label: 'Highly Interested'),
          ContentOptionModel(optionKey: 'react_curious', label: 'Open to Details'),
          ContentOptionModel(optionKey: 'react_skip', label: 'Skip for Now'),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_5',
        format: 'INTENT_CHOICE',
        titlePrompt: 'If a verified vendor offers flexible wholesale terms on trending stock:',
        description: 'Detects active purchase readiness and inventory scaling intent.',
        contextType: 'business',
        poolType: 'PERSONALIZED',
        orderIndex: 5,
        options: [
          ContentOptionModel(
            optionKey: 'act_now',
            label: 'Request Price Catalog',
            subtext: 'Looking to purchase stock this week',
          ),
          ContentOptionModel(
            optionKey: 'act_wait',
            label: 'Bookmark for Next Cycle',
            subtext: 'Planning inventory for coming month',
          ),
          ContentOptionModel(
            optionKey: 'act_alt',
            label: 'Compare Other Vendors',
            subtext: 'Seeking alternative category suppliers',
          ),
        ],
      ),
    ];
  }

  Future<void> _handleOptionSelected(String optionKey, String interactionType) async {
    if (_items.isEmpty || _cardIndex >= _items.length) return;

    HapticFeedback.selectionClick();
    final currentItem = _items[_cardIndex];
    final dwellMs = DateTime.now().difference(_cardStartTime).inMilliseconds;

    final interestService = ref.read(interestServiceProvider);
    interestService.submitWallInteraction(
      sessionId: _sessionId,
      contentId: currentItem.contentId,
      format: currentItem.format,
      optionId: optionKey,
      interactionType: interactionType,
      dwellMs: dwellMs,
    );

    if (_cardIndex >= _items.length - 1) {
      HapticFeedback.mediumImpact();
      if (_sessionId != null) {
        interestService.completeDailyWallSession(_sessionId!);
      }
      ref.read(userStateProvider.notifier).completeDailyWall();
      if (mounted) {
        context.go('/home');
      }
    } else {
      setState(() {
        _cardIndex++;
        _cardStartTime = DateTime.now();
      });
    }
  }

  Widget _buildCardContent(WallSessionItemModel item) {
    switch (item.format) {
      case 'THIS_OR_THAT':
        return ThisOrThatCardRenderer(item: item, onSelect: _handleOptionSelected);
      case 'PICK_ONE':
        return PickOneCardRenderer(item: item, onSelect: _handleOptionSelected);
      case 'WOULD_YOU':
        return WouldYouCardRenderer(item: item, onSelect: _handleOptionSelected);
      case 'REACTION_CARD':
        return ReactionCardRenderer(item: item, onSelect: _handleOptionSelected);
      case 'SCENARIO':
        return ScenarioCardRenderer(item: item, onSelect: _handleOptionSelected);
      case 'COMPARE':
        return CompareCardRenderer(item: item, onSelect: _handleOptionSelected);
      case 'QUICK_OPINION':
        return QuickOpinionCardRenderer(item: item, onSelect: _handleOptionSelected);
      case 'INTENT_CHOICE':
      default:
        return IntentChoiceCardRenderer(item: item, onSelect: _handleOptionSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 140, height: 16),
                const SizedBox(height: 12),
                const ShimmerBox(width: double.infinity, height: 28),
                const SizedBox(height: 24),
                Expanded(
                  child: ShimmerLoading(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const ShimmerBox(width: double.infinity, height: 50, borderRadius: 14),
              ],
            ),
          ),
        ),
      );
    }

    final currentItem = _items[_cardIndex];
    final progress = (_cardIndex + 1) / _items.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Step Counter & Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedFlash,
                              color: Color(0xFF0058FF),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Daily Alignment',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0058FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Card ${_cardIndex + 1} of ${_items.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(userStateProvider.notifier).completeDailyWall();
                      context.go('/home');
                    },
                    child: Text(
                      'Skip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0058FF)),
                ),
              ),

              const SizedBox(height: 20),

              // Question Title & Subtext
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Column(
                  key: ValueKey(currentItem.contentId),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentItem.titlePrompt,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                        height: 1.3,
                      ),
                    ),
                    if (currentItem.description != null && currentItem.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        currentItem.description!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reel Card Interactive Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(currentItem.contentId),
                    child: _buildCardContent(currentItem),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
