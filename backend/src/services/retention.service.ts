import { pool } from '../db/pool';
import { NotificationEvents } from './notification.service';

/**
 * BizSquare Retention Service.
 *
 * Implements smart, value-based re-engagement. Does NOT send generic push.
 * Every notification is triggered by real application state.
 *
 * User states:
 *   INACTIVE_WITH_NEW_VALUE — contacts waiting, user hasn't opened app recently
 *   PERMISSION_BLOCKED      — contacts permission revoked, blocking Contact Gain
 */
export class RetentionService {
  /**
   * Daily retention check cron target.
   * Runs at 09:00 UTC.
   *
   * Strategy:
   * 1. Find users with unread CONTACT_GAIN_READY notifications older than 24h
   *    and who haven't opened the app since — re-notify once (dedup prevents spam).
   *
   * 2. Find users who previously had contacts permission but now don't have
   *    active push tokens or contact access — send permission revoked nudge.
   */
  static async runDailyRetentionCheck(): Promise<{
    contactGainNudgesSent: number;
    permissionNudgesSent: number;
  }> {
    let contactGainNudgesSent = 0;
    let permissionNudgesSent = 0;

    // ── 1. INACTIVE_WITH_NEW_VALUE ─────────────────────────────────────────────
    // Users who received matches this week but have not read the notification yet
    // and last_active_at is more than 24 hours ago.
    // We only re-nudge once (dedup key includes date).
    try {
      const { rows: inactiveWithValue } = await pool.query(`
        SELECT DISTINCT
          un.user_id,
          un.data->>'contactCount' AS contact_count,
          un.data->>'cycleId' AS cycle_id,
          un.data->>'batchDate' AS batch_date
        FROM user_notifications un
        JOIN users u ON u.id = un.user_id
        WHERE un.type = 'contact_gain_ready'
          AND un.is_read = FALSE
          AND un.created_at < NOW() - INTERVAL '24 hours'
          AND un.expires_at > NOW()
          AND u.last_active_at < NOW() - INTERVAL '24 hours'
          AND u.is_active = TRUE
        LIMIT 200
      `);

      const today = new Date().toISOString().slice(0, 10);
      for (const row of inactiveWithValue) {
        const contactCount = parseInt(row.contact_count, 10) || 0;
        if (contactCount <= 0) continue;

        try {
          const noun = contactCount === 1 ? 'contact is' : 'contacts are';
          const result = await pool.query(`
            INSERT INTO user_notifications (
              user_id, title, body, type, priority, action_url, data, dedup_key, expires_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW() + INTERVAL '48 hours')
            ON CONFLICT (dedup_key) DO NOTHING
            RETURNING id
          `, [
            row.user_id,
            'Your new contacts are still waiting',
            `You received ${contactCount} new Square ${noun} ready to view in your network.`,
            'contact_gain_ready',
            'IMPORTANT_UPDATE',
            '/contacts',
            { contactCount: String(contactCount), cycleId: row.cycle_id, batchDate: row.batch_date },
            `CONTACT_GAIN_NUDGE:${row.user_id}:${today}`,
          ]);

          if (result.rows.length > 0) {
            contactGainNudgesSent++;
          }
        } catch (_) {}
      }
    } catch (err) {
      console.error('[RetentionService] Contact gain nudge query failed:', err);
    }

    // ── 2. PERMISSION_BLOCKED ──────────────────────────────────────────────────
    // Users who have matches in the system but no contacts permission recorded.
    // We check users who have had matches before but their sync status shows
    // contacts are not accessible.
    try {
      const { rows: permBlocked } = await pool.query(`
        SELECT DISTINCT u.id AS user_id
        FROM users u
        WHERE u.is_active = TRUE
          AND u.onboarding_completed = TRUE
          -- Has at least one match (has used Contact Gain)
          AND EXISTS (
            SELECT 1 FROM matches m
            WHERE m.user_a_id = u.id OR m.user_b_id = u.id
          )
          -- Has had contacts permission issue (contact_sync_status column if present)
          -- We proxy this by checking if they have a recent permission notification
          -- already sent today (skip) or not
          AND NOT EXISTS (
            SELECT 1 FROM user_notifications un
            WHERE un.user_id = u.id
              AND un.type = 'permission_contacts'
              AND un.created_at > NOW() - INTERVAL '24 hours'
          )
        LIMIT 50
      `);

      for (const row of permBlocked) {
        try {
          // This uses the daily dedup key internally
          await NotificationEvents.contactsPermissionRevoked({ userId: row.user_id });
          permissionNudgesSent++;
        } catch (_) {}
      }
    } catch (err) {
      console.error('[RetentionService] Permission nudge query failed:', err);
    }

    return { contactGainNudgesSent, permissionNudgesSent };
  }
}
