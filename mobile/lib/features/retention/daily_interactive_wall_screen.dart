import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/motion/motion_primitives.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class DailyWallCard {
  final String id;
  final String type; // this_or_that | slider | pick_multiple | scenario_choice | quick_response
  final String taxonomyId;
  final String category;
  final String question;
  final String hint;
  final Map<String, dynamic> rawJson;

  const DailyWallCard({
    required this.id,
    required this.type,
    required this.taxonomyId,
    required this.category,
    required this.question,
    required this.hint,
    required this.rawJson,
  });

  factory DailyWallCard.fromJson(Map<String, dynamic> json) {
    return DailyWallCard(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'quick_response',
      taxonomyId: json['taxonomyId'] as String? ?? 'general',
      category: json['category'] as String? ?? 'General Demand',
      question: json['question'] as String? ?? 'What is your primary focus this week?',
      hint: json['hint'] as String? ?? 'Tap your choice.',
      rawJson: json,
    );
  }
}

class DailyInteractiveWallScreen extends ConsumerStatefulWidget {
  const DailyInteractiveWallScreen({super.key});

  @override
  ConsumerState<DailyInteractiveWallScreen> createState() => _DailyInteractiveWallScreenState();
}

class _DailyInteractiveWallScreenState extends ConsumerState<DailyInteractiveWallScreen> {
  bool _isLoading = true;
  List<DailyWallCard> _cards = [];
  int _currentIndex = 0;
  int _completedCount = 0;
  String? _feedbackMessage;
  bool _isSubmitting = false;
  double _sliderValue = 0.5;
  final Set<String> _selectedMultiple = {};

  @override
  void initState() {
    super.initState();
    _loadWallSession();
  }

  Future<void> _loadWallSession() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.dio.get('/retention/wall/session');
      final List rawCards = resp.data['cards'] ?? [];
      final cards = rawCards.map((c) => DailyWallCard.fromJson(c)).toList();

      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitInteraction({
    required String cardId,
    required String interactionType,
    required Map<String, dynamic> responseValue,
    required String taxonomyId,
    bool skipped = false,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.dio.post('/retention/wall/interaction', data: {
        'cardId': cardId,
        'interactionType': interactionType,
        'responseValue': responseValue,
        'taxonomyId': taxonomyId,
        'skipped': skipped,
      });

      final feedback = resp.data['feedbackMessage'] as String? ?? 'Got it';

      setState(() {
        _isSubmitting = false;
        _completedCount++;
        _feedbackMessage = feedback;
      });

      // Clear feedback message after 1.8 seconds
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _feedbackMessage = null;
            if (_currentIndex < _cards.length - 1) {
              _currentIndex++;
              _selectedMultiple.clear();
              _sliderValue = 0.5;
            } else {
              _currentIndex = _cards.length; // Session complete
            }
          });
        }
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Daily Network Pulse',
          style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            color: AppTheme.primaryBlue,
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Immediate Contextual Feedback Header Banner (Section 3)
                    if (_feedbackMessage != null)
                      StateTransitionSwitcher(
                        keyObject: _feedbackMessage!,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _feedbackMessage!,
                                  style: AppTheme.satoshi(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Purpose Header (Section 4)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedIdea01,
                              color: AppTheme.primaryBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'These quick choices sharpen your demand for weekly Contact Gain.',
                                style: AppTheme.satoshi(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Main Card Area / Session Completion View
                    Expanded(
                      child: _currentIndex < _cards.length
                          ? _buildInteractiveCard(context, _cards[_currentIndex], isDark)
                          : _buildSessionCompletedView(context, isDark),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInteractiveCard(BuildContext context, DailyWallCard card, bool isDark) {
    return StateTransitionSwitcher(
      keyObject: card.id,
      child: Container(
        key: ValueKey(card.id),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                card.category.toUpperCase(),
                style: AppTheme.satoshi(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Question
            Text(
              card.question,
              style: AppTheme.satoshi(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.hint,
              style: AppTheme.satoshi(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const Spacer(),

            // Dynamic Interaction Body based on card type
            _buildCardInteractionBody(card, isDark),

            const Spacer(),

            // Skip / Dismiss
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitInteraction(
                          cardId: card.id,
                          interactionType: card.type,
                          responseValue: {'action': 'skipped'},
                          taxonomyId: card.taxonomyId,
                          skipped: true,
                        ),
                child: Text(
                  'Skip for now',
                  style: AppTheme.satoshi(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInteractionBody(DailyWallCard card, bool isDark) {
    switch (card.type) {
      case 'this_or_that':
        final optA = card.rawJson['optionA'] as Map? ?? {};
        final optB = card.rawJson['optionB'] as Map? ?? {};
        return Row(
          children: [
            Expanded(
              child: PressableScale(
                onTap: () => _submitInteraction(
                  cardId: card.id,
                  interactionType: 'this_or_that',
                  responseValue: {'choice': optA['label']},
                  taxonomyId: card.taxonomyId,
                ),
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        optA['label'] ?? 'Option A',
                        textAlign: TextAlign.center,
                        style: AppTheme.satoshi(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PressableScale(
                onTap: () => _submitInteraction(
                  cardId: card.id,
                  interactionType: 'this_or_that',
                  responseValue: {'choice': optB['label']},
                  taxonomyId: card.taxonomyId,
                ),
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        optB['label'] ?? 'Option B',
                        textAlign: TextAlign.center,
                        style: AppTheme.satoshi(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

      case 'slider':
        final minL = card.rawJson['minLabel'] ?? 'Low';
        final maxL = card.rawJson['maxLabel'] ?? 'High';
        return Column(
          children: [
            Slider(
              value: _sliderValue,
              onChanged: (val) => setState(() => _sliderValue = val),
              activeColor: AppTheme.primaryBlue,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(minL, style: AppTheme.satoshi(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                Text(maxL, style: AppTheme.satoshi(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _submitInteraction(
                  cardId: card.id,
                  interactionType: 'slider',
                  responseValue: {'value': _sliderValue},
                  taxonomyId: card.taxonomyId,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Confirm Preference', style: AppTheme.satoshi(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        );

      case 'quick_response':
      case 'scenario_choice':
      default:
        final List options = card.rawJson['options'] ?? ['Yes', 'No'];
        return Column(
          children: options.map<Widget>((opt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              child: PressableScale(
                onTap: () => _submitInteraction(
                  cardId: card.id,
                  interactionType: card.type,
                  responseValue: {'choice': opt.toString()},
                  taxonomyId: card.taxonomyId,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt.toString(),
                          style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: AppTheme.primaryBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
    }
  }

  Widget _buildSessionCompletedView(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedSparkles,
            color: Color(0xFF10B981),
            size: 44,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Network Profile Sharpened',
          style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Your preferences have been updated ($_completedCount choice${_completedCount == 1 ? '' : 's'} recorded). The matching engine will use these signals for your next Contact Gain cycle.',
          textAlign: TextAlign.center,
          style: AppTheme.satoshi(
            fontSize: 13,
            height: 1.4,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Done for Today',
              style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
