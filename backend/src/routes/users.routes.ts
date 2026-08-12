import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { pool } from '../db/pool';

const router = Router();

/**
 * GET /api/v1/users/me
 * Returns complete user profile
 */
router.get('/me', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { rows: [user] } = await pool.query(
      `SELECT 
        id, phone_number, full_name, business_name, avatar_id, 
        akawo_points, is_active, onboarding_completed, created_at 
       FROM users 
       WHERE id = $1`,
      [userId]
    );

    if (!user) {
      res.status(404).json({ success: false, error: 'User not found' });
      return;
    }

    // Supply micro-niches
    const { rows: supplyNiches } = await pool.query(
      `SELECT bmn.micro_niche_id, bmn.is_primary, mn.name
       FROM business_micro_niches bmn
       JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
       WHERE bmn.user_id = $1`,
      [userId]
    );

    // Baseline interests
    const { rows: baselineInterests } = await pool.query(
      `SELECT ubi.taxonomy_id, it.name, it.slug
       FROM user_baseline_interests ubi
       JOIN interest_taxonomies it ON it.id = ubi.taxonomy_id
       WHERE ubi.user_id = $1`,
      [userId]
    );

    res.json({
      success: true,
      user: {
        ...user,
        supplyNiches,
        baselineInterests,
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/v1/users/setup-status
 * Returns real setup step completion flags from database
 */
router.get('/setup-status', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;

    // 1. Profile completed check
    const { rows: [user] } = await pool.query(
      `SELECT business_name, full_name, avatar_id, onboarding_completed FROM users WHERE id = $1`,
      [userId]
    );
    const profileCompleted = Boolean(user && (user.business_name || user.full_name));

    // 2. Primary offer set check
    const { rows: primaryOffers } = await pool.query(
      `SELECT id FROM business_micro_niches WHERE user_id = $1 AND is_primary = TRUE`,
      [userId]
    );
    const primaryOfferSet = primaryOffers.length > 0;

    // 3. Baseline interests set check
    const { rows: baselineRows } = await pool.query(
      `SELECT id FROM user_baseline_interests WHERE user_id = $1`,
      [userId]
    );
    const { rows: legRows } = await pool.query(
      `SELECT id FROM baseline_demand WHERE user_id = $1 AND is_active = TRUE`,
      [userId]
    );
    const interestsSet = (baselineRows.length + legRows.length) > 0;

    res.json({
      success: true,
      data: {
        profileCompleted,
        primaryOfferSet,
        interestsSet,
        onboardingCompleted: Boolean(user?.onboarding_completed),
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;
