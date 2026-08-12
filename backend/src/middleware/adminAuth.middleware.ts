import { Response, NextFunction } from 'express';
import { AuthRequest, authenticateJWT } from './auth.middleware';
import { pool } from '../db/pool';

export const requireAdmin = [
  authenticateJWT,
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized. No user ID.' });
      }

      const { rows } = await pool.query(
        `SELECT access_level FROM users WHERE id = $1`,
        [userId]
      );

      if (rows.length === 0) {
        return res.status(404).json({ error: 'User not found.' });
      }

      const accessLevel = rows[0].access_level;
      if (accessLevel !== 'admin' && accessLevel !== 'super_admin') {
        return res.status(403).json({ error: 'Forbidden. Admin access required.' });
      }

      next();
    } catch (error) {
      res.status(500).json({ error: 'Internal server error during authorization check.' });
    }
  }
];
