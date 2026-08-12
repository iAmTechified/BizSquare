import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { RetentionAnalyticsService, RetentionEventType } from '../services/retention_analytics.service';
import { DemandConcentrationService } from '../services/demand_concentration.service';
import { pool } from '../db/pool';

const router = Router();

/**
 * POST /api/v1/retention/analytics/event
 * Log retention telemetry event (Section 19)
 */
router.post('/analytics/event', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { eventType, metadata } = req.body;

    if (!eventType || typeof eventType !== 'string') {
      res.status(400).json({ success: false, error: 'eventType is required' });
      return;
    }

    await RetentionAnalyticsService.trackEvent(
      userId,
      eventType as RetentionEventType,
      metadata || {}
    );

    res.json({ success: true, message: 'Event tracked.' });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/v1/retention/wall/session
 * Returns personalized Daily Interactive Wall session cards (Sections 2, 5, 6)
 * Low effort, short session (1-3 cards), natural stopping point.
 */
router.get('/wall/session', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;

    // Track wall opened event
    await RetentionAnalyticsService.trackEvent(userId, 'daily_wall_opened');

    // Fetch user's completed wall card IDs from memory
    const { rows: memoryRows } = await pool.query(
      `SELECT card_id FROM user_wall_memory WHERE user_id = $1`,
      [userId]
    );
    const seenCardIds = new Set(memoryRows.map(r => r.card_id));

    // Curated interactive wall scenarios (THIS_OR_THAT, PICK_MULTIPLE, SLIDER, QUICK_RESPONSE, SCENARIO_CHOICE)
    const allCards = [
      {
        id: 'wall_001',
        type: 'this_or_that',
        taxonomyId: 'niche_fashion',
        category: 'Fashion & Apparel',
        question: 'Which network partners fit your business demand best this week?',
        optionA: { label: 'Wholesale Fabric Suppliers', icon: 'fabric' },
        optionB: { label: 'Custom Tailors & Designers', icon: 'scissors' },
        hint: 'Quick tap to clarify your demand preference.',
      },
      {
        id: 'wall_002',
        type: 'slider',
        taxonomyId: 'niche_logistics',
        category: 'Delivery & Logistics',
        question: 'How important is same-day nationwide dispatch for your current orders?',
        minLabel: 'Standard (2-3 days)',
        maxLabel: 'Urgent Same-Day',
        hint: 'Slide to adjust matching priority.',
      },
      {
        id: 'wall_003',
        type: 'pick_multiple',
        taxonomyId: 'niche_tech',
        category: 'Software & Digital Services',
        question: 'Select services your business needs in the next 30 days:',
        options: [
          'E-commerce Website Development',
          'Social Media Ads Management',
          'POS & Inventory Software',
          'Corporate Branding & Graphics',
        ],
        hint: 'Select all that apply.',
      },
      {
        id: 'wall_004',
        type: 'scenario_choice',
        taxonomyId: 'niche_food',
        category: 'Food & Catering Services',
        question: 'A corporate client requests bulk catering for 150 guests on short notice. What is your priority partner need?',
        options: [
          'Bulk Fresh Ingredient Suppliers',
          'Professional Service Waitstaff',
          'Refrigerated Transport Delivery',
          'Event Decorators & Setup',
        ],
        hint: 'Tap your primary operational bottleneck.',
      },
      {
        id: 'wall_005',
        type: 'quick_response',
        taxonomyId: 'niche_real_estate',
        category: 'Real Estate & Properties',
        question: 'Are you currently looking for commercial office or warehouse space partners?',
        options: ['Yes, actively', 'Open to offers', 'Not right now'],
        hint: 'One-tap response.',
      },
    ];

    // Filter cards not yet seen, fallback to all if all seen
    let availableCards = allCards.filter(c => !seenCardIds.has(c.id));
    if (availableCards.length === 0) {
      availableCards = allCards; // Recirculate with recency refresh
    }

    // Return maximum 3 cards per session (Short Session Design — Section 5)
    const sessionCards = availableCards.slice(0, 3);

    res.json({
      success: true,
      cards: sessionCards,
      totalAvailable: sessionCards.length,
      sessionTarget: 1, // 1 interaction is enough, optional continuation
      stoppingMessage: 'Your network profile for this cycle is sharp!',
    });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/retention/wall/interaction
 * Record user response on Daily Interactive Wall card (Sections 3, 4, 7)
 */
router.post('/wall/interaction', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { cardId, interactionType, responseValue, taxonomyId, skipped } = req.body;

    if (!cardId || typeof cardId !== 'string') {
      res.status(400).json({ success: false, error: 'cardId is required' });
      return;
    }

    const result = await DemandConcentrationService.recordInteraction({
      userId,
      cardId,
      interactionType: interactionType || 'tap',
      responseValue: responseValue || {},
      taxonomyId,
      skipped: Boolean(skipped),
    });

    res.json({
      success: true,
      feedbackMessage: result.feedbackMessage,
      confidenceUpdated: result.confidenceUpdated,
    });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/v1/retention/demand-profile
 * Get user's demand concentration profile (Section 9)
 */
router.get('/demand-profile', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const profile = await DemandConcentrationService.getConcentrationProfile(userId);
    res.json({ success: true, profile });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
