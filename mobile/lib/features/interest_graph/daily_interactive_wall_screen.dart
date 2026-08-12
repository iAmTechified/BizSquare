import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/wall_content_model.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/services/interest_service.dart';
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
        // Fallback default curated multi-format items if offline / initial setup
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
        titlePrompt: 'Which would you rather upgrade right now?',
        description: 'Preference between mobile smartphone hardware and workstation laptops.',
        contextType: 'general',
        poolType: 'PERSONALIZED',
        orderIndex: 1,
        options: [
          ContentOptionModel(optionKey: 'opt_a', label: 'Latest Flagship Smartphone', subtext: 'Top camera, battery & speed'),
          ContentOptionModel(optionKey: 'opt_b', label: 'High-Performance Laptop', subtext: 'Workstation speed for business'),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_2',
        format: 'WOULD_YOU',
        titlePrompt: 'Would you test noise-cancelling audio earbuds for daily commuting & calls?',
        description: 'Testing audio gear curiosity and work environment preferences.',
        contextType: 'lifestyle',
        poolType: 'RELATED',
        orderIndex: 2,
        options: [
          ContentOptionModel(optionKey: 'yes', label: 'Definitely Yes 🔥', subtext: 'I value crystal sound'),
          ContentOptionModel(optionKey: 'maybe', label: 'Maybe / Curious 👀', subtext: 'Looking for reviews'),
          ContentOptionModel(optionKey: 'no', label: 'Not for Me', subtext: 'Standard audio is fine'),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_3',
        format: 'SCENARIO',
        titlePrompt: 'You receive a ₦100,000 growth grant this week. Where does it create the most impact?',
        description: 'Reveals commercial priorities and high-leverage bottlenecks.',
        contextType: 'business',
        poolType: 'EXPLORATION',
        orderIndex: 3,
        options: [
          ContentOptionModel(optionKey: 'opt_ads', label: 'Targeted Ads & Acquisition', subtext: 'Drive direct leads'),
          ContentOptionModel(optionKey: 'opt_dispatch', label: 'Express Delivery Logistics', subtext: 'Same-day customer fulfillment'),
          ContentOptionModel(optionKey: 'opt_brand', label: 'Packaging & Branding', subtext: 'Elevate unboxing experience'),
          ContentOptionModel(optionKey: 'opt_solar', label: 'Solar Power Inverter', subtext: 'Keep operations 24/7'),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_4',
        format: 'REACTION_CARD',
        titlePrompt: 'Mobile 4K Video Rig & Studio Lighting for Product Showcases',
        description: 'Testing interest in video creation and photography production tools.',
        contextType: 'emerging',
        poolType: 'BROAD',
        orderIndex: 4,
        options: [
          ContentOptionModel(optionKey: 'react_love', label: '❤️ Interested'),
          ContentOptionModel(optionKey: 'react_curious', label: '👀 Curious'),
          ContentOptionModel(optionKey: 'react_skip', label: '⏭️ Skip'),
        ],
      ),
      WallSessionItemModel(
        contentId: 'fallback_5',
        format: 'INTENT_CHOICE',
        titlePrompt: 'If a verified supplier offers flexible-payment clean solar power setup:',
        description: 'Detects active purchase readiness and clean energy demand.',
        contextType: 'business',
        poolType: 'PERSONALIZED',
        orderIndex: 5,
        options: [
          ContentOptionModel(optionKey: 'act_now', label: 'Get Quote Now ⚡', subtext: 'Urgently need clean power'),
          ContentOptionModel(optionKey: 'act_wait', label: 'Save for Later', subtext: 'Planning for next quarter'),
          ContentOptionModel(optionKey: 'act_alt', label: 'Explore Alternatives', subtext: 'Looking at other options'),
        ],
      ),
    ];
  }

  Future<void> _handleOptionSelected(String optionKey, String interactionType) async {
    if (_items.isEmpty || _cardIndex >= _items.length) return;

    final currentItem = _items[_cardIndex];
    final dwellMs = DateTime.now().difference(_cardStartTime).inMilliseconds;

    // Asynchronously submit interaction event with idempotency
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
      // Completed all items
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
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0058FF)),
        ),
      );
    }

    final currentItem = _items[_cardIndex];
    final progress = (_cardIndex + 1) / _items.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Daily Wall',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_cardIndex + 1} / ${_items.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0058FF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0058FF)),
                ),
              ),
              const SizedBox(height: 18),

              // Title Prompt Header
              Text(
                currentItem.titlePrompt,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (currentItem.description != null && currentItem.format != 'REACTION_CARD') ...[
                const SizedBox(height: 6),
                Text(
                  currentItem.description!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Format-Specific Dynamic Card Container
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(currentItem.contentId),
                    child: _buildCardContent(currentItem),
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
