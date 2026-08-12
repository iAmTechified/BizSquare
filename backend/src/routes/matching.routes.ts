import { Router, Request, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { MatchingEngineService } from '../services/matching/matching_engine.service';
import { MatchingAnalyticsService } from '../services/matching_analytics.service';
import { MATCHING_CONFIG } from '../config/matching.config';
import { pool } from '../db/pool';

const router = Router();

/**
 * GET /api/v1/matching/user/summary
 * Returns user Contact Gain progress, weekly target, and recently gained contacts
 */
router.get('/user/summary', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;

    // 1. Get active network size for 10% target calculation
    const { rows: [{ count: userCount }] } = await pool.query(
      `SELECT COUNT(*) FROM users WHERE is_active = TRUE AND onboarding_completed = TRUE`
    );
    const networkSize = parseInt(userCount, 10) || 1;
    const weeklyTarget = MATCHING_CONFIG.calculateWeeklyTarget(networkSize);

    // 2. Fetch latest cycle summary for this user
    const { rows: [summary] } = await pool.query(`
      SELECT cas.*, wmc.batch_date
      FROM cycle_allocation_summaries cas
      JOIN weekly_matching_cycles wmc ON wmc.id = cas.cycle_id
      WHERE cas.user_id = $1
      ORDER BY wmc.batch_date DESC
      LIMIT 1
    `, [userId]);

    // 3. Fetch recently gained contacts for this user (Square Contacts)
    const { rows: recentContacts } = await pool.query(`
      SELECT 
        uc.id as contact_id,
        uc.created_at as gained_date,
        uc.notes,
        u.id as user_id,
        u.business_name,
        u.full_name,
        u.phone_number,
        u.avatar_id,
        COALESCE(mn.name, 'Verified Business') as primary_offer,
        ma.match_reason,
        ma.tier,
        ma.is_mutual,
        ma.final_score
      FROM user_contacts uc
      JOIN users u ON u.id = uc.contact_user_id
      LEFT JOIN business_micro_niches bmn ON bmn.user_id = u.id AND bmn.is_primary = TRUE
      LEFT JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
      LEFT JOIN match_allocations ma ON ma.user_id = uc.owner_id AND ma.candidate_user_id = uc.contact_user_id
      WHERE uc.owner_id = $1
      ORDER BY uc.created_at DESC
      LIMIT 15
    `, [userId]);

    // 4. Check sync status
    const { rows: pendingSyncRows } = await pool.query(`
      SELECT id FROM contact_relationships
      WHERE (user_a_id = $1 OR user_b_id = $1) AND sync_status = 'PENDING_SYNC'
      LIMIT 1
    `, [userId]);
    const isSyncPending = pendingSyncRows.length > 0;

    const gainedThisWeek = summary ? summary.allocated_count : recentContacts.length;
    const remainingCount = Math.max(0, weeklyTarget - gainedThisWeek);

    let status = 'IN_PROGRESS';
    if (gainedThisWeek === 0) {
      status = 'NO_CONTACTS';
    } else if (isSyncPending) {
      status = 'SYNC_PENDING';
    } else if (gainedThisWeek >= weeklyTarget) {
      status = 'TARGET_REACHED';
    } else if (summary && summary.allocation_status === 'UNDERFILLED') {
      status = 'UNDERFILLED';
    }

    res.json({
      success: true,
      data: {
        weeklyTarget,
        gainedThisWeek,
        remainingCount,
        status,
        syncStatus: isSyncPending ? 'PENDING_SYNC' : 'SYNCED',
        underfillReason: summary?.underfill_reason || null,
        batchDate: summary?.batch_date || new Date().toISOString().split('T')[0],
        recentContacts: recentContacts.map(r => ({
          contactId: r.contact_id,
          userId: r.user_id,
          businessName: r.business_name,
          fullName: r.full_name,
          phoneNumber: r.phone_number,
          avatarId: r.avatar_id || 1,
          primaryOffer: r.primary_offer,
          gainedDate: r.gained_date,
          matchReason: r.match_reason || 'WEEKLY_CONTACT_GAIN',
          tier: r.tier || 'TIER_1',
          isMutual: Boolean(r.is_mutual),
          score: r.final_score ? parseFloat(r.final_score) : 100.0,
        })),
      },
    });
  } catch (error: any) {
    console.error('Error fetching user matching summary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user matching summary',
      error: error.message,
    });
  }
});

/**
 * POST /api/v1/matching/cycles/run
 * Manually or programmatically triggers a weekly matching cycle
 */
router.post('/cycles/run', async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await MatchingEngineService.runWeeklyMatchingCycle();
    res.json({
      success: true,
      message: 'Weekly matching cycle executed successfully',
      data: result,
    });
  } catch (error: any) {
    console.error('Error running weekly matching cycle:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to run matching cycle',
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/matching/analytics
 * Returns network matching KPIs, tier breakdown, and cycle history
 */
router.get('/analytics', async (req: Request, res: Response): Promise<void> => {
  try {
    const analytics = await MatchingAnalyticsService.getMatchingAnalytics();
    res.json({
      success: true,
      data: analytics,
    });
  } catch (error: any) {
    console.error('Error fetching matching analytics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch matching analytics',
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/matching/cycles/:id
 * Returns detailed user summaries for a specific cycle
 */
router.get('/cycles/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const cycleId = String(req.params.id);
    const details = await MatchingAnalyticsService.getCycleDetails(cycleId);
    if (!details) {
      res.status(404).json({ success: false, message: 'Cycle not found' });
      return;
    }
    res.json({
      success: true,
      data: details,
    });
  } catch (error: any) {
    console.error('Error fetching cycle details:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch cycle details',
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/matching/users/:id/matches
 * Returns explainable match history for a user
 */
router.get('/users/:id/matches', async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = String(req.params.id);
    const matches = await MatchingAnalyticsService.getUserMatchHistory(userId);
    res.json({
      success: true,
      data: matches,
    });
  } catch (error: any) {
    console.error('Error fetching user match history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user match history',
      error: error.message,
    });
  }
});

export default router;
