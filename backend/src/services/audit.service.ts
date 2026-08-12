import { pool } from '../db/pool';
import { AuthRequest } from '../middleware/auth.middleware';

export interface AuditLogParams {
  action: string;
  resourceType: string;
  resourceId?: string;
  metadata?: Record<string, any>;
  result?: 'success' | 'failure';
}

export class AuditService {
  /**
   * Records an administrative audit event to PostgreSQL audit_logs table.
   * Securely derives adminUserId from the authenticated session.
   */
  static async logEvent(req: AuthRequest, params: AuditLogParams): Promise<void> {
    try {
      const adminUserId = req.user?.id;
      if (!adminUserId) {
        console.warn('AuditService.logEvent called without authenticated admin user context.');
        return;
      }

      const ipAddress = (req.headers['x-forwarded-for'] as string) || req.socket?.remoteAddress || '127.0.0.1';
      const userAgent = req.headers['user-agent'] || 'Unknown';

      await pool.query(
        `INSERT INTO audit_logs (admin_user_id, action, resource_type, resource_id, metadata, ip_address, user_agent, result)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          adminUserId,
          params.action,
          params.resourceType,
          params.resourceId || null,
          JSON.stringify(params.metadata || {}),
          ipAddress,
          userAgent,
          params.result || 'success',
        ]
      );
    } catch (error) {
      console.error('Failed to write audit log event:', error);
      // Non-blocking for the main request path, but logged to stderr
    }
  }

  /**
   * Retrieves recent audit logs from PostgreSQL database.
   */
  static async getAuditLogs(limit: number = 50, offset: number = 0) {
    const { rows } = await pool.query(
      `SELECT 
        al.id,
        al.admin_user_id,
        u.full_name as admin_name,
        u.phone_number as admin_phone,
        al.action,
        al.resource_type,
        al.resource_id,
        al.metadata,
        al.ip_address,
        al.result,
        al.created_at
       FROM audit_logs al
       JOIN users u ON u.id = al.admin_user_id
       ORDER BY al.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    return rows;
  }
}
