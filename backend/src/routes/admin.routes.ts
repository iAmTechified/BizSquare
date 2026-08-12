import { Router, Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { requireAdmin } from '../middleware/adminAuth.middleware';
import { pool } from '../db/pool';

const router = Router();

// Apply admin middleware to all routes in this file
router.use(requireAdmin);

router.get('/analytics/network', async (req: AuthRequest, res: Response) => {
  try {
    const { rows: userCount } = await pool.query(`SELECT COUNT(*) FROM users WHERE is_active = true`);
    const { rows: matchCount } = await pool.query(`SELECT COUNT(*) FROM matches`);
    const { rows: pointsTotal } = await pool.query(`SELECT SUM(akawo_points) as total_points FROM users`);

    res.json({
      active_users: parseInt(userCount[0].count, 10),
      total_matches: parseInt(matchCount[0].count, 10),
      total_points_in_circulation: parseInt(pointsTotal[0].total_points || '0', 10)
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/users', async (req: AuthRequest, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;

    const { rows } = await pool.query(
      `SELECT id, phone_number, full_name, akawo_points, access_level, is_active, last_login, created_at 
       FROM users 
       ORDER BY created_at DESC 
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    res.json({ users: rows });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/users/:id/suspend', async (req: AuthRequest, res: Response) => {
  try {
    const targetUserId = req.params.id;
    const { suspend } = req.body; // true to suspend, false to unsuspend

    const isActive = suspend !== true; // If suspend is true, is_active becomes false

    const { rows } = await pool.query(
      `UPDATE users SET is_active = $1 WHERE id = $2 RETURNING id, is_active`,
      [isActive, targetUserId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ success: true, user: rows[0] });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
