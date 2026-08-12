import { pool } from '../db/pool';
import { PushService } from './push.service';
import {
  NotificationEventRegistry,
  NotificationSource,
  NotificationCategory,
  NotificationPriority,
  VisualVariant,
  SoundVariant,
} from './notification_event_registry';

export interface DispatchEventParams {
  recipientUserId: string;
  eventType: string;
  source?: NotificationSource;
  deduplicationKey: string;
  params?: Record<string, any>;
  customTitle?: string;
  customBody?: string;
  customDeepLink?: string;
  expiresInHours?: number;
  scheduledAt?: string;
}

export class NotificationFoundationService {
  /**
   * Main Unified Event-to-Notification Pipeline (Section 3)
   */
  static async dispatchEvent(eventParams: DispatchEventParams): Promise<{
    status: 'SENT' | 'SUPPRESSED' | 'EXPIRED' | 'DUPLICATE' | 'FAILED';
    notificationId?: string;
    reason?: string;
  }> {
    const {
      recipientUserId,
      eventType,
      source = 'BACKEND',
      deduplicationKey,
      params = {},
      customTitle,
      customBody,
      customDeepLink,
      expiresInHours,
      scheduledAt,
    } = eventParams;

    // 1. Event Idempotency Check (Section 4)
    const { rows: existingRows } = await pool.query(
      `SELECT id, status FROM user_notifications WHERE dedup_key = $1`,
      [deduplicationKey]
    );

    if (existingRows.length > 0) {
      await NotificationFoundationService.trackAnalytics({
        userId: recipientUserId,
        notificationId: existingRows[0].id,
        eventType: 'notification_suppressed',
        source,
        metadata: { reason: 'duplicate_dedup_key', dedupKey: deduplicationKey },
      });
      return { status: 'DUPLICATE', reason: 'Deduplicated by dedup_key' };
    }

    // 2. Lookup Event Definition in Registry
    const eventDef = NotificationEventRegistry[eventType];
    const category: NotificationCategory = eventDef?.category || 'SYSTEM';
    const priority: NotificationPriority = eventDef?.priority || 'INFORMATIONAL';
    const visualVariant: VisualVariant = eventDef?.visualVariant || 'DEFAULT';
    const soundVariant: SoundVariant = eventDef?.soundVariant || 'DEFAULT';

    // 3. User Notification Preferences Check (Section 9)
    if (category !== 'SYSTEM') {
      const { rows: prefRows } = await pool.query(
        `SELECT enabled FROM user_notification_preferences WHERE user_id = $1 AND category = $2`,
        [recipientUserId, category]
      );
      if (prefRows.length > 0 && prefRows[0].enabled === false) {
        await NotificationFoundationService.trackAnalytics({
          userId: recipientUserId,
          eventType: 'notification_suppressed',
          source,
          metadata: { reason: 'user_category_disabled', category },
        });
        return { status: 'SUPPRESSED', reason: `Category ${category} disabled by user` };
      }
    }

    // 4. Template Rendering & Personalization (Section 10 - No Generic Fallbacks)
    let title: string;
    let body: string;
    let deepLink: string;

    if (customTitle && customBody) {
      title = customTitle;
      body = customBody;
      deepLink = customDeepLink || eventDef?.defaultDeepLink || 'bizsquare://notifications';
    } else if (eventDef) {
      try {
        const rendered = eventDef.render(params);
        title = rendered.title;
        body = rendered.body;
        deepLink = customDeepLink || rendered.deepLink;
      } catch (err) {
        // Suppress delivery if variable resolution fails (Section 10)
        await NotificationFoundationService.trackAnalytics({
          userId: recipientUserId,
          eventType: 'notification_suppressed',
          source,
          metadata: { reason: 'template_rendering_failed', error: String(err) },
        });
        return { status: 'SUPPRESSED', reason: 'Template rendering failed' };
      }
    } else {
      title = 'BizSquare Update';
      body = 'You have a new update in your BizSquare network.';
      deepLink = 'bizsquare://notifications';
    }

    // 5. Expiration Handling (Section 6)
    const expiresAt = expiresInHours
      ? new Date(Date.now() + expiresInHours * 3600000).toISOString()
      : null;

    // 6. Save Notification to Unified Table
    let notificationId: string;
    try {
      const { rows: inserted } = await pool.query(
        `INSERT INTO user_notifications (
           user_id, source, event_type, category, priority, title, body,
           visual_variant, sound_variant, action_url, data, payload,
           dedup_key, status, scheduled_at, expires_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
         RETURNING id`,
        [
          recipientUserId,
          source,
          eventType,
          category,
          priority,
          title,
          body,
          visualVariant,
          soundVariant,
          deepLink,
          JSON.stringify(params),
          JSON.stringify({ eventType, source, category, priority }),
          deduplicationKey,
          'SENT',
          scheduledAt ? new Date(scheduledAt) : null,
          expiresAt ? new Date(expiresAt) : null,
        ]
      );
      notificationId = inserted[0].id;
    } catch (dbErr: any) {
      if (dbErr.code === '23505') {
        // Unique violation on dedup_key
        return { status: 'DUPLICATE', reason: 'Deduplicated' };
      }
      throw dbErr;
    }

    // 7. Track Created Analytics (Section 8)
    await NotificationFoundationService.trackAnalytics({
      userId: recipientUserId,
      notificationId,
      eventType: 'notification_created',
      source,
      metadata: { category, priority, deepLink },
    });

    // 8. Deliver FCM Push asynchronously
    setImmediate(async () => {
      try {
        const pushPriority = priority === 'IMPORTANT' ? 'IMPORTANT_UPDATE' : (priority as 'ACTION_REQUIRED' | 'INFORMATIONAL');
        const pushResult = await PushService.sendToUser({
          userId: recipientUserId,
          notificationId,
          payload: {
            title,
            body,
            deepLink,
            priority: pushPriority,
            data: { type: eventType, dedupKey: deduplicationKey, category },
          },
        });

        if (pushResult.sent > 0) {
          await NotificationFoundationService.trackAnalytics({
            userId: recipientUserId,
            notificationId,
            eventType: 'notification_sent',
            source,
            metadata: { sentCount: pushResult.sent },
          });
        }
      } catch (pushErr) {
        await NotificationFoundationService.trackAnalytics({
          userId: recipientUserId,
          notificationId,
          eventType: 'notification_failed',
          source,
          metadata: { error: String(pushErr) },
        });
      }
    });

    return { status: 'SENT', notificationId };
  }

  /**
   * Admin Broadcast or Targeted Dispatch (Section 1 Source B)
   */
  static async sendAdminNotification(params: {
    recipientUserIds?: string[];
    broadcastAll?: boolean;
    title: string;
    body: string;
    category?: NotificationCategory;
    priority?: NotificationPriority;
    deepLink?: string;
  }): Promise<{ dispatchedCount: number }> {
    let targetIds: string[] = params.recipientUserIds || [];

    if (params.broadcastAll) {
      const { rows } = await pool.query(`SELECT id FROM users WHERE is_active = TRUE`);
      targetIds = rows.map((r) => r.id);
    }

    const todayStr = new Date().toISOString().slice(0, 10);
    let count = 0;

    for (const userId of targetIds) {
      const dedupKey = `ADMIN_MSG:${userId}:${todayStr}:${params.title.slice(0, 20)}`;
      const res = await NotificationFoundationService.dispatchEvent({
        recipientUserId: userId,
        eventType: 'admin.broadcast',
        source: 'ADMIN',
        deduplicationKey: dedupKey,
        customTitle: params.title,
        customBody: params.body,
        customDeepLink: params.deepLink || 'bizsquare://notifications',
      });

      if (res.status === 'SENT') count++;
    }

    return { dispatchedCount: count };
  }

  /**
   * Telemetry Event Tracker (Section 8)
   */
  static async trackAnalytics(params: {
    userId: string | null;
    notificationId?: string;
    eventType: string;
    source?: string;
    metadata?: Record<string, any>;
  }): Promise<void> {
    try {
      await pool.query(
        `INSERT INTO notification_analytics (user_id, notification_id, event_type, source, metadata)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          params.userId,
          params.notificationId || null,
          params.eventType,
          params.source || 'BACKEND',
          JSON.stringify(params.metadata || {}),
        ]
      );
    } catch (err) {
      console.error('[NotificationAnalytics] Track failed:', err);
    }
  }

  /**
   * Fetches User Notification Category Preferences (Section 9)
   */
  static async getUserPreferences(userId: string): Promise<Record<string, boolean>> {
    const { rows } = await pool.query(
      `SELECT category, enabled FROM user_notification_preferences WHERE user_id = $1`,
      [userId]
    );

    const defaultPrefs: Record<string, boolean> = {
      CONTACT_GAIN: true,
      SPOTLIGHT: true,
      DAILY_PULSE: true,
      SYSTEM: true, // Non-disableable
    };

    for (const r of rows) {
      if (r.category !== 'SYSTEM') {
        defaultPrefs[r.category] = Boolean(r.enabled);
      }
    }

    return defaultPrefs;
  }

  /**
   * Updates User Notification Category Preferences (Section 9)
   */
  static async updateUserPreferences(
    userId: string,
    preferences: Record<string, boolean>
  ): Promise<Record<string, boolean>> {
    for (const [category, enabled] of Object.entries(preferences)) {
      if (category === 'SYSTEM') continue; // Critical system notifications cannot be disabled

      await pool.query(
        `INSERT INTO user_notification_preferences (user_id, category, enabled, updated_at)
         VALUES ($1, $2, $3, NOW())
         ON CONFLICT (user_id, category) DO UPDATE SET
           enabled = EXCLUDED.enabled,
           updated_at = NOW()`,
        [userId, category, Boolean(enabled)]
      );
    }

    return NotificationFoundationService.getUserPreferences(userId);
  }
}
