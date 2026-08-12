import { pool } from '../db/pool';
import { PushService } from './push.service';

// ─── Types ────────────────────────────────────────────────────────────────────

export type NotificationPriority = 'ACTION_REQUIRED' | 'IMPORTANT_UPDATE' | 'INFORMATIONAL';

export type NotificationType =
  | 'contact_gain_ready'
  | 'contact_gain_cycle_approaching'
  | 'spotlight_turn'
  | 'spotlight_verified'
  | 'spotlight_result'
  | 'permission_contacts'
  | 'sync_problem'
  | 'system';

export interface UserNotificationItem {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: NotificationType | string;
  priority: NotificationPriority;
  isRead: boolean;
  actionUrl?: string | undefined;
  deepLink?: string | undefined;
  data: Record<string, any>;
  createdAt: string;
  expiresAt?: string | undefined;
}

export interface GetNotificationsResult {
  notifications: UserNotificationItem[];
  unreadCount: number;
  totalCount: number;
  hasMore: boolean;
}

// ─── Service ──────────────────────────────────────────────────────────────────

export class NotificationService {
  /**
   * Fetches user notifications and unread count with optional filter & pagination.
   */
  static async getUserNotifications(
    userId: string,
    options: { filter?: 'all' | 'unread'; page?: number; limit?: number } = {}
  ): Promise<GetNotificationsResult> {
    const filter = options.filter || 'all';
    const page = Math.max(1, options.page || 1);
    const limit = Math.min(50, Math.max(1, options.limit || 30));
    const offset = (page - 1) * limit;

    // Exclude expired notifications
    let query = `
      SELECT * FROM user_notifications
      WHERE user_id = $1
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    `;
    const queryParams: any[] = [userId];

    if (filter === 'unread') {
      query += ` AND is_read = FALSE`;
    }

    query += ` ORDER BY created_at DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
    queryParams.push(limit, offset);

    const { rows } = await pool.query(query, queryParams);

    // Unread count (excludes expired)
    const { rows: [{ count: unreadCountStr }] } = await pool.query(`
      SELECT COUNT(*) FROM user_notifications
      WHERE user_id = $1 AND is_read = FALSE
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    `, [userId]);

    // Total count for current filter
    let totalCountQuery = `
      SELECT COUNT(*) FROM user_notifications
      WHERE user_id = $1
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    `;
    if (filter === 'unread') {
      totalCountQuery += ` AND is_read = FALSE`;
    }
    const { rows: [{ count: totalCountStr }] } = await pool.query(totalCountQuery, [userId]);

    const unreadCount = parseInt(unreadCountStr, 10) || 0;
    const totalCount = parseInt(totalCountStr, 10) || 0;
    const hasMore = offset + rows.length < totalCount;

    return {
      notifications: rows.map(NotificationService._mapRow),
      unreadCount,
      totalCount,
      hasMore,
    };
  }

  /**
   * Creates a notification AND sends push — all with deduplication.
   *
   * If dedupKey is provided and a notification with that key already exists,
   * the creation is skipped and no push is sent. This prevents duplicate
   * notifications from overlapping cron runs or event double-fires.
   *
   * Returns the notification if created, or null if deduplication prevented creation.
   */
  static async createAndPush(params: {
    userId: string;
    title: string;
    body: string;
    type: NotificationType;
    priority?: NotificationPriority;
    deepLink?: string;
    dedupKey?: string;
    data?: Record<string, any>;
    expiresInHours?: number; // Auto-expire stale notifications
  }): Promise<UserNotificationItem | null> {
    const {
      userId,
      title,
      body,
      type,
      priority = 'INFORMATIONAL',
      deepLink,
      dedupKey,
      data = {},
      expiresInHours,
    } = params;

    // Calculate expiry if set
    const expiresAt = expiresInHours
      ? new Date(Date.now() + expiresInHours * 60 * 60 * 1000).toISOString()
      : null;

    // Deduplication — ON CONFLICT DO NOTHING prevents duplicates
    const { rows } = await pool.query(`
      INSERT INTO user_notifications (
        user_id, title, body, type, priority, action_url, data, dedup_key, expires_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ON CONFLICT (dedup_key) DO NOTHING
      RETURNING *
    `, [
      userId,
      title,
      body,
      type,
      priority,
      deepLink || null,
      data,
      dedupKey || null,
      expiresAt,
    ]);

    if (rows.length === 0) {
      // Duplicate — silently skipped
      return null;
    }

    const notification = NotificationService._mapRow(rows[0]);

    // Track creation analytics
    await NotificationService._trackEvent(userId, notification.id, 'notification_created');

    // Fire push asynchronously — non-blocking, never fails the in-app creation
    setImmediate(async () => {
      try {
        const result = await PushService.sendToUser({
          userId,
          notificationId: notification.id,
          payload: {
            title,
            body,
            deepLink,
            priority,
            data: { type, ...(dedupKey ? { dedupKey } : {}) },
          },
        });

        if (result.sent > 0) {
          await NotificationService._trackEvent(userId, notification.id, 'notification_sent', {
            sent: result.sent,
            failed: result.failed,
          });
        }
      } catch (pushErr) {
        console.error('[NotificationService] Push delivery error (non-fatal):', pushErr);
      }
    });

    return notification;
  }

  /**
   * Creates a notification WITHOUT push (for system/internal events).
   */
  static async createNotification(params: {
    userId: string;
    title: string;
    body: string;
    type?: string;
    actionUrl?: string;
    deepLink?: string;
    priority?: NotificationPriority;
    dedupKey?: string;
    data?: Record<string, any>;
  }): Promise<UserNotificationItem> {
    const { rows } = await pool.query(`
      INSERT INTO user_notifications (
        user_id, title, body, type, priority, action_url, data, dedup_key
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      ON CONFLICT (dedup_key) DO NOTHING
      RETURNING *
    `, [
      params.userId,
      params.title,
      params.body,
      params.type || 'system',
      params.priority || 'INFORMATIONAL',
      params.deepLink || params.actionUrl || null,
      params.data || {},
      params.dedupKey || null,
    ]);

    if (rows.length === 0) {
      // Deduplicated — return a neutral placeholder
      throw new Error('DUPLICATE_NOTIFICATION');
    }

    return NotificationService._mapRow(rows[0]);
  }

  /**
   * Marks notifications as read and tracks open analytics.
   */
  static async markAsRead(
    userId: string,
    notificationIds?: string[]
  ): Promise<{ markedCount: number; unreadCount: number }> {
    if (notificationIds && notificationIds.length > 0) {
      await pool.query(`
        UPDATE user_notifications
        SET is_read = TRUE, opened_at = COALESCE(opened_at, CURRENT_TIMESTAMP)
        WHERE user_id = $1 AND id = ANY($2)
      `, [userId, notificationIds]);

      // Track opened analytics for each
      for (const id of notificationIds) {
        await NotificationService._trackEvent(userId, id, 'notification_opened');
        await PushService.recordOpened(id);
      }
    } else {
      await pool.query(`
        UPDATE user_notifications
        SET is_read = TRUE, opened_at = COALESCE(opened_at, CURRENT_TIMESTAMP)
        WHERE user_id = $1
      `, [userId]);
    }

    const { rows: [{ count: unreadCountStr }] } = await pool.query(`
      SELECT COUNT(*) FROM user_notifications
      WHERE user_id = $1 AND is_read = FALSE
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    `, [userId]);

    return {
      markedCount: notificationIds ? notificationIds.length : 0,
      unreadCount: parseInt(unreadCountStr, 10) || 0,
    };
  }

  /**
   * Marks notifications as unread (e.g. undo mark-read).
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
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    `, [userId]);

    return {
      unreadCount: parseInt(unreadCountStr, 10) || 0,
    };
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  private static _mapRow(r: any): UserNotificationItem {
    return {
      id: r.id,
      userId: r.user_id,
      title: r.title,
      body: r.body,
      type: r.type,
      priority: r.priority || 'INFORMATIONAL',
      isRead: r.is_read,
      actionUrl: r.action_url || undefined,
      deepLink: r.action_url || undefined,
      data: r.data || {},
      createdAt: r.created_at.toISOString(),
      expiresAt: r.expires_at ? r.expires_at.toISOString() : undefined,
    };
  }

  private static async _trackEvent(
    userId: string,
    notificationId: string,
    eventType: string,
    metadata: Record<string, any> = {}
  ): Promise<void> {
    try {
      await pool.query(`
        INSERT INTO notification_analytics (user_id, notification_id, event_type, metadata)
        VALUES ($1, $2, $3, $4)
      `, [userId, notificationId, eventType, metadata]);
    } catch (_) {
      // Analytics must never block the main flow
    }
  }
}

// ─── Domain Event Factories ───────────────────────────────────────────────────
// These are the only functions that should be called to create MVP notifications.
// Each encapsulates the exact copy, dedup key, deep link, and priority for that event.

export const NotificationEvents = {
  /**
   * CONTACT_GAIN_READY — fired after weekly matchmaking completes.
   * Only sent if the user received > 0 contacts.
   */
  contactGainReady: async (params: {
    userId: string;
    contactCount: number;
    cycleId: string;
    batchDate: string;
  }) => {
    if (params.contactCount <= 0) return null;

    const noun = params.contactCount === 1 ? 'contact' : 'contacts';
    return NotificationService.createAndPush({
      userId: params.userId,
      type: 'contact_gain_ready',
      priority: 'IMPORTANT_UPDATE',
      title: 'Your new contacts are ready',
      body: `You received ${params.contactCount} new Square ${noun} this week. Open to see who joined your network.`,
      deepLink: '/contacts',
      dedupKey: `CONTACT_GAIN_READY:${params.cycleId}:${params.userId}`,
      expiresInHours: 72,
      data: {
        contactCount: String(params.contactCount),
        cycleId: params.cycleId,
        batchDate: params.batchDate,
      },
    });
  },

  /**
   * SPOTLIGHT_TURN — fired when the cycle's featured user is assigned.
   */
  spotlightTurn: async (params: {
    userId: string;
    cycleId: string;
    cycleEndDate: string;
  }) => {
    return NotificationService.createAndPush({
      userId: params.userId,
      type: 'spotlight_turn',
      priority: 'ACTION_REQUIRED',
      title: "It's your Spotlight turn",
      body: `Your business is being featured this cycle. Submit your post before ${params.cycleEndDate} to maximize reach.`,
      deepLink: '/spotlight',
      dedupKey: `SPOTLIGHT_TURN:${params.cycleId}:${params.userId}`,
      expiresInHours: 48,
      data: { cycleId: params.cycleId, cycleEndDate: params.cycleEndDate },
    });
  },

  /**
   * SPOTLIGHT_VERIFIED — fired after admin verifies the user's submission.
   */
  spotlightVerified: async (params: {
    userId: string;
    cycleId: string;
    participantCount: number;
  }) => {
    return NotificationService.createAndPush({
      userId: params.userId,
      type: 'spotlight_verified',
      priority: 'IMPORTANT_UPDATE',
      title: 'Your Spotlight has been verified',
      body: `Your post is live and ${params.participantCount} member${params.participantCount === 1 ? '' : 's'} in your network can now share it.`,
      deepLink: '/spotlight',
      dedupKey: `SPOTLIGHT_VERIFIED:${params.cycleId}:${params.userId}`,
      expiresInHours: 48,
      data: { cycleId: params.cycleId, participantCount: String(params.participantCount) },
    });
  },

  /**
   * PERMISSION_CONTACTS_REVOKED — fired when sync detects contacts permission is off.
   * Uses cooldown dedup key (per day) to prevent spam.
   */
  contactsPermissionRevoked: async (params: {
    userId: string;
  }) => {
    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
    return NotificationService.createAndPush({
      userId: params.userId,
      type: 'permission_contacts',
      priority: 'ACTION_REQUIRED',
      title: 'Contact access is off',
      body: 'Turn it back on to keep Contact Gain working and stay connected to your network.',
      deepLink: '/profile/contact-sync',
      dedupKey: `PERMISSION_CONTACTS:${params.userId}:${today}`,
      expiresInHours: 24,
    });
  },

  /**
   * SYNC_PROBLEM — fired when the contact sync engine encounters a persistent failure.
   */
  syncProblem: async (params: {
    userId: string;
    reason: string;
  }) => {
    const today = new Date().toISOString().slice(0, 10);
    return NotificationService.createAndPush({
      userId: params.userId,
      type: 'sync_problem',
      priority: 'ACTION_REQUIRED',
      title: 'Contact sync needs attention',
      body: 'There was a problem syncing your contacts. Tap to fix it and keep your network up to date.',
      deepLink: '/profile/contact-sync',
      dedupKey: `SYNC_PROBLEM:${params.userId}:${today}`,
      expiresInHours: 24,
      data: { reason: params.reason },
    });
  },
};
