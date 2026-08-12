import { pool } from '../db/pool';

export type RetentionEventType =
  | 'daily_wall_opened'
  | 'daily_wall_interaction'
  | 'daily_wall_completed'
  | 'daily_wall_skipped'
  | 'interest_signal_created'
  | 'interest_signal_strengthened'
  | 'interest_signal_decayed'
  | 'contact_gain_ready'
  | 'contact_gain_viewed'
  | 'square_contact_opened'
  | 'square_contact_actioned'
  | 'spotlight_opened'
  | 'spotlight_completed'
  | 'widget_opened'
  | 'push_opened';

export class RetentionAnalyticsService {
  /**
   * Tracks a retention event in the database (non-blocking).
   */
  static async trackEvent(
    userId: string | null,
    eventType: RetentionEventType,
    metadata: Record<string, any> = {}
  ): Promise<void> {
    try {
      await pool.query(
        `INSERT INTO retention_analytics (user_id, event_type, metadata)
         VALUES ($1, $2, $3)`,
        [userId, eventType, metadata]
      );
    } catch (err) {
      // Telemetry must never crash primary business flow
      console.error(`[RetentionAnalytics] Failed to track ${eventType}:`, err);
    }
  }

  /**
   * Summarizes user engagement telemetry for evaluation.
   */
  static async getUserSummary(userId: string): Promise<{
    wallInteractionsCount: number;
    contactsOpenedCount: number;
    lastWallActivityAt: string | null;
  }> {
    const { rows: [{ wallCount }] } = await pool.query(
      `SELECT COUNT(*) as "wallCount" FROM retention_analytics 
       WHERE user_id = $1 AND event_type = 'daily_wall_interaction'`,
      [userId]
    );

    const { rows: [{ contactsCount }] } = await pool.query(
      `SELECT COUNT(*) as "contactsCount" FROM retention_analytics 
       WHERE user_id = $1 AND event_type = 'square_contact_opened'`,
      [userId]
    );

    const { rows: [lastAct] } = await pool.query(
      `SELECT created_at FROM retention_analytics 
       WHERE user_id = $1 AND event_type LIKE 'daily_wall_%'
       ORDER BY created_at DESC LIMIT 1`,
      [userId]
    );

    return {
      wallInteractionsCount: parseInt(wallCount, 10) || 0,
      contactsOpenedCount: parseInt(contactsCount, 10) || 0,
      lastWallActivityAt: lastAct?.created_at ? lastAct.created_at.toISOString() : null,
    };
  }
}
