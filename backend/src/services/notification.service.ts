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

export interface GetNotificationsResult {
  notifications: UserNotificationItem[];
  unreadCount: number;
  totalCount: number;
  hasMore: boolean;
}

export class NotificationService {
  /**
   * Fetches user notifications and unread count with optional filter & pagination
   */
  static async getUserNotifications(
    userId: string,
    options: { filter?: 'all' | 'unread'; page?: number; limit?: number } = {}
  ): Promise<GetNotificationsResult> {
    const filter = options.filter || 'all';
    const page = Math.max(1, options.page || 1);
    const limit = Math.min(50, Math.max(1, options.limit || 30));
    const offset = (page - 1) * limit;

    let query = `
      SELECT * FROM user_notifications
      WHERE user_id = $1
    `;
    const queryParams: any[] = [userId];

    if (filter === 'unread') {
      query += ` AND is_read = FALSE`;
    }

    query += ` ORDER BY created_at DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
    queryParams.push(limit, offset);

    const { rows } = await pool.query(query, queryParams);

    // Count unread
    const { rows: [{ count: unreadCountStr }] } = await pool.query(`
      SELECT COUNT(*) FROM user_notifications
      WHERE user_id = $1 AND is_read = FALSE
    `, [userId]);

    // Count total for this filter
    let totalCountQuery = `SELECT COUNT(*) FROM user_notifications WHERE user_id = $1`;
    if (filter === 'unread') {
      totalCountQuery += ` AND is_read = FALSE`;
    }
    const { rows: [{ count: totalCountStr }] } = await pool.query(totalCountQuery, [userId]);

    const unreadCount = parseInt(unreadCountStr, 10) || 0;
    const totalCount = parseInt(totalCountStr, 10) || 0;
    const hasMore = offset + rows.length < totalCount;

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
      unreadCount,
      totalCount,
      hasMore,
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
  }): Promise<UserNotificationItem> {
    const { rows } = await pool.query(`
      INSERT INTO user_notifications (
        user_id, title, body, type, action_url, data
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      )
      RETURNING *
    `, [
      params.userId,
      params.title,
      params.body,
      params.type || 'system',
      params.actionUrl || null,
      params.data || {},
    ]);

    const r = rows[0];
    return {
      id: r.id,
      userId: r.user_id,
      title: r.title,
      body: r.body,
      type: r.type,
      isRead: r.is_read,
      actionUrl: r.action_url || undefined,
      data: r.data || {},
      createdAt: r.created_at.toISOString(),
    };
  }

  /**
   * Marks notifications as read
   */
  static async markAsRead(
    userId: string,
    notificationIds?: string[]
  ): Promise<{ markedCount: number; unreadCount: number }> {
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

    const { rows: [{ count: unreadCountStr }] } = await pool.query(`
      SELECT COUNT(*) FROM user_notifications
      WHERE user_id = $1 AND is_read = FALSE
    `, [userId]);

    return {
      markedCount: notificationIds ? notificationIds.length : 0,
      unreadCount: parseInt(unreadCountStr, 10) || 0,
    };
  }

  /**
   * Marks notifications as unread (e.g., swipe action or undo)
   */
  static async markAsUnread(
    userId: string,
    notificationIds: string[]
  ): Promise<{ unreadCount: number }> {
    if (notificationIds && notificationIds.length > 0) {
      await pool.query(`
        UPDATE user_notifications
        SET is_read = FALSE
        WHERE user_id = $1 AND id = ANY($2)
      `, [userId, notificationIds]);
    }

    const { rows: [{ count: unreadCountStr }] } = await pool.query(`
      SELECT COUNT(*) FROM user_notifications
      WHERE user_id = $1 AND is_read = FALSE
    `, [userId]);

    return {
      unreadCount: parseInt(unreadCountStr, 10) || 0,
    };
  }
}
