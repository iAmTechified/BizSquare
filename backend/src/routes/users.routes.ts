import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { pool } from '../db/pool';
import { NotificationService } from '../services/notification.service';

const router = Router();

/**
 * GET /api/v1/users/me
 * Returns complete user profile including primary/secondary offers and baseline interests
 */
router.get('/me', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { rows: [user] } = await pool.query(
      `SELECT 
        id, phone_number, full_name, business_name, username, avatar_id, 
        akawo_points, is_active, onboarding_completed, verification_status, created_at 
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
 * PUT /api/v1/users/profile
 * Updates editable user profile fields (business_name, full_name, avatar_id)
 */
router.put('/profile', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { businessName, fullName, avatarId } = req.body;

    const { rows: [updatedUser] } = await pool.query(
      `UPDATE users 
       SET 
         business_name = COALESCE($1, business_name),
         full_name = COALESCE($2, full_name),
         avatar_id = COALESCE($3, avatar_id)
       WHERE id = $4
       RETURNING id, phone_number, full_name, business_name, username, avatar_id, akawo_points`,
      [businessName, fullName, avatarId, userId]
    );

    if (!updatedUser) {
      res.status(404).json({ success: false, error: 'User not found' });
      return;
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: updatedUser,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * PUT /api/v1/users/offers
 * Updates user's primary offer and secondary offers (up to 2)
 */
router.put('/offers', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  const client = await pool.connect();
  try {
    const userId = req.user.id;
    const { primaryMicroNicheId, secondaryMicroNicheIds } = req.body;

    if (!primaryMicroNicheId) {
      res.status(400).json({ success: false, error: 'primaryMicroNicheId is required' });
      return;
    }

    const secondaries: string[] = Array.isArray(secondaryMicroNicheIds) ? secondaryMicroNicheIds : [];
    if (secondaries.length > 2) {
      res.status(400).json({ success: false, error: 'Maximum 2 secondary offerings allowed' });
      return;
    }

    // Mutual exclusion validation: primary cannot be in secondaries
    if (secondaries.includes(primaryMicroNicheId)) {
      res.status(400).json({ success: false, error: 'Primary offering cannot also be a secondary offering' });
      return;
    }

    await client.query('BEGIN');

    // Remove existing supply niches
    await client.query(`DELETE FROM business_micro_niches WHERE user_id = $1`, [userId]);

    // Insert primary niche
    await client.query(
      `INSERT INTO business_micro_niches (user_id, micro_niche_id, is_primary)
       VALUES ($1, $2, TRUE)`,
      [userId, primaryMicroNicheId]
    );

    // Insert secondary niches
    for (const secId of secondaries) {
      await client.query(
        `INSERT INTO business_micro_niches (user_id, micro_niche_id, is_primary)
         VALUES ($1, $2, FALSE)
         ON CONFLICT (user_id, micro_niche_id) DO NOTHING`,
        [userId, secId]
      );
    }

    await client.query('COMMIT');

    // Fetch updated supply niches
    const { rows: supplyNiches } = await pool.query(
      `SELECT bmn.micro_niche_id, bmn.is_primary, mn.name
       FROM business_micro_niches bmn
       JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
       WHERE bmn.user_id = $1`,
      [userId]
    );

    res.json({
      success: true,
      message: 'Business offerings updated successfully',
      supplyNiches,
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, error: error.message });
  } finally {
    client.release();
  }
});

/**
 * PUT /api/v1/users/pin
 * Changes user's 4-digit security PIN
 */
router.put('/pin', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { currentPin, newPin } = req.body;

    if (!newPin || newPin.length !== 4) {
      res.status(400).json({ success: false, error: 'New PIN must be exactly 4 digits' });
      return;
    }

    const { rows: [user] } = await pool.query(
      `SELECT pin_hash FROM users WHERE id = $1`,
      [userId]
    );

    if (!user) {
      res.status(404).json({ success: false, error: 'User not found' });
      return;
    }

    if (user.pin_hash) {
      if (!currentPin) {
        res.status(400).json({ success: false, error: 'Current PIN is required' });
        return;
      }
      const isMatch = await bcrypt.compare(currentPin, user.pin_hash);
      if (!isMatch) {
        res.status(401).json({ success: false, error: 'Current PIN is incorrect' });
        return;
      }
    }

    const newPinHash = await bcrypt.hash(newPin, 10);
    await pool.query(
      `UPDATE users SET pin_hash = $1 WHERE id = $2`,
      [newPinHash, userId]
    );

    // Create security notification
    try {
      await NotificationService.createNotification({
        userId,
        title: 'Security PIN updated',
        body: 'Your 4-digit security PIN was successfully changed.',
        type: 'account',
        actionUrl: '/profile/account',
      });
    } catch (_) {}

    res.json({
      success: true,
      message: 'PIN updated successfully',
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * DELETE /api/v1/users/me
 * Deactivates user account (soft delete)
 */
router.delete('/me', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    await pool.query(
      `UPDATE users SET is_active = FALSE WHERE id = $1`,
      [userId]
    );

    res.json({
      success: true,
      message: 'Account deactivated successfully',
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
