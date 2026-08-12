import { pool } from '../db/pool';

export interface UserNotificationItem {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: string;
  isRead: boolean;
  actionUrl?: string | undefined;
  data: Record<string, any>;
  createdAt: string;
}

export class NotificationService {
  /**
   * Fetches user notifications and unread count
   */
  static async getUserNotifications(userId: string): Promise<{ notifications: UserNotificationItem[]; unreadCount: number }> {
    const { rows } = await pool.query(`
      SELECT * FROM user_notifications
      WHERE user_id = $1
      ORDER BY created_at DESC
      LIMIT 30
    `, [userId]);

    const { rows: [{ count }] } = await pool.query(`
      SELECT COUNT(*) FROM user_notifications
      WHERE user_id = $1 AND is_read = FALSE
    `, [userId]);

    return {
      notifications: rows.map(r => ({
        id: r.id,
        userId: r.user_id,
        title: r.title,
        body: r.body,
        type: r.type,
        isRead: r.is_read,
        actionUrl: r.action_url || undefined,
        data: r.data || {},
        createdAt: r.created_at.toISOString(),
      })),
      unreadCount: parseInt(count, 10) || 0,
    };
  }

  /**
   * Creates a notification for a user
   */
  static async createNotification(params: {
    userId: string;
    title: string;
    body: string;
    type?: string;
    actionUrl?: string;
    data?: Record<string, any>;
  }): Promise<void> {
    await pool.query(`
      INSERT INTO user_notifications (
        user_id, title, body, type, action_url, data
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      )
    `, [
      params.userId,
      params.title,
      params.body,
      params.type || 'system',
      params.actionUrl || null,
      params.data || {},
    ]);
  }

  /**
   * Marks notifications as read
   */
  static async markAsRead(userId: string, notificationIds?: string[]): Promise<void> {
    if (notificationIds && notificationIds.length > 0) {
      await pool.query(`
        UPDATE user_notifications
        SET is_read = TRUE
        WHERE user_id = $1 AND id = ANY($2)
      `, [userId, notificationIds]);
    } else {
      // Mark all read
      await pool.query(`
        UPDATE user_notifications
        SET is_read = TRUE
        WHERE user_id = $1
      `, [userId]);
    }
  }
}
