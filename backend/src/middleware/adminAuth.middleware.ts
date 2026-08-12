import { Response, NextFunction } from 'express';
import { AuthRequest, authenticateJWT } from './auth.middleware';
import { pool } from '../db/pool';

export type AdminPermission =
  | 'users.view'
  | 'users.manage'
  | 'contacts.view'
  | 'contacts.manage'
  | 'spotlight.view'
  | 'spotlight.manage'
  | 'spotlight.moderate'
  | 'spotlight.override'
  | 'notifications.view'
  | 'notifications.send'
  | 'interests.manage'
  | 'content.view'
  | 'content.manage'
  | 'analytics.view'
  | 'system.view'
  | 'system.manage'
  | 'admins.manage'
  | 'audit.view'
  | '*';

/**
 * Default permission matrix for Admin access levels.
 */
export const ROLE_PERMISSIONS_MAP: Record<string, AdminPermission[]> = {
  super_admin: ['*'],
  admin: [
    'users.view',
    'users.manage',
    'contacts.view',
    'contacts.manage',
    'spotlight.view',
    'spotlight.manage',
    'spotlight.moderate',
    'spotlight.override',
    'notifications.view',
    'notifications.send',
    'interests.manage',
    'content.view',
    'content.manage',
    'analytics.view',
    'system.view',
    'audit.view',
  ],
  support_admin: ['users.view', 'contacts.view', 'spotlight.view', 'notifications.view'],
};

/**
 * Middleware: Verifies that the request comes from an authenticated user
 * whose access_level is 'admin' or 'super_admin'.
 * Attaches user profile and resolved permissions list to req.user.
 */
export const requireAdmin = [
  authenticateJWT,
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized. Authentication token missing or invalid.' });
      }

      const { rows } = await pool.query(
        `SELECT id, full_name, phone_number, akawo_points, access_level, is_active, created_at 
         FROM users WHERE id = $1`,
        [userId]
      );

      if (rows.length === 0) {
        return res.status(401).json({ error: 'Unauthorized. Account not found.' });
      }

      const user = rows[0];

      if (!user.is_active) {
        return res.status(403).json({ error: 'Forbidden. Administrative account has been suspended.' });
      }

      const accessLevel = user.access_level;
      if (accessLevel !== 'admin' && accessLevel !== 'super_admin') {
        return res.status(403).json({ 
          error: 'Access Denied. You do not have administrative privileges to access this area.',
          access_level: accessLevel 
        });
      }

      const permissions = ROLE_PERMISSIONS_MAP[accessLevel] || ROLE_PERMISSIONS_MAP.admin;

      // Attach complete user context to request
      req.user = {
        id: user.id,
        full_name: user.full_name,
        phone_number: user.phone_number,
        access_level: accessLevel,
        permissions,
        created_at: user.created_at,
      };

      next();
    } catch (error: any) {
      console.error('Admin authorization middleware error:', error);
      res.status(500).json({ error: 'Internal server error during authorization verification.' });
    }
  },
];

/**
 * Middleware factory: Ensures the authenticated admin possesses a specific permission.
 */
export const requirePermission = (permission: AdminPermission) => {
  return [
    ...requireAdmin,
    (req: AuthRequest, res: Response, next: NextFunction) => {
      const userPermissions: AdminPermission[] = req.user?.permissions || [];
      const hasPermission =
        userPermissions.includes('*') || userPermissions.includes(permission);

      if (!hasPermission) {
        return res.status(403).json({
          error: `Forbidden. Required permission '${permission}' is missing for role '${req.user?.access_level}'.`,
          required_permission: permission,
        });
      }

      next();
    },
  ];
};
