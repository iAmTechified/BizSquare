import { pool } from '../db/pool';
import { NotificationFoundationService } from './notification_foundation.service';

export type SpotlightReminderStyle = 'ALERT' | 'RING' | 'PROGRESS' | 'SOCIAL' | 'FINAL_CALL';

export class SpotlightNotificationService {
  /**
   * Main cron / event handler for sending Spotlight reminders (Sections 2, 3, 5, 6)
   */
  static async runSpotlightReminderCheck(): Promise<{ processedCount: number; remindersSent: number }> {
    const client = await pool.connect();
    let remindersSent = 0;

    try {
      // 1. Fetch active campaigns with unfulfilled turn
      const { rows: campaigns } = await client.query(`
        SELECT 
          sc.id as campaign_id,
          sc.user_id,
          sc.end_date,
          sc.submission_status,
          u.full_name,
          u.business_name
        FROM spotlight_campaigns sc
        JOIN users u ON u.id = sc.user_id
        WHERE sc.is_active = TRUE
          AND sc.end_date >= CURRENT_DATE
          AND sc.submission_status IN ('not_submitted', 'pending', 'needs_changes')
      `);

      for (const campaign of campaigns) {
        const userId = campaign.user_id;
        const campaignId = campaign.campaign_id;

        // Skip if submission is already verified or completed (Section 5)
        if (campaign.submission_status === 'verified') {
          await SpotlightNotificationService.cancelRemindersForTurn(userId, campaignId);
          continue;
        }

        // Quiet hours check: 22:00 - 08:00 UTC (Section 6)
        const currentHour = new Date().getUTCHours();
        if (currentHour >= 22 || currentHour < 8) {
          await NotificationFoundationService.trackAnalytics({
            userId,
            eventType: 'spotlight_notification_suppressed',
            source: 'BACKEND',
            metadata: { reason: 'quiet_hours', currentHour },
          });
          continue;
        }

        // Calculate hours remaining until turn end
        const endDateMs = new Date(campaign.end_date).getTime();
        const nowMs = Date.now();
        const timeRemainingHours = Math.max(1, Math.round((endDateMs - nowMs) / (1000 * 60 * 60)));

        // Fetch previous reminder history for this turn
        const { rows: history } = await client.query(`
          SELECT * FROM spotlight_reminders_log
          WHERE user_id = $1 AND campaign_id = $2
          ORDER BY sent_at DESC
        `, [userId, campaignId]);

        const reminderCount = history.length;

        // Maximum reminders per turn limit = 4 (Section 6)
        if (reminderCount >= 4) {
          continue;
        }

        // Minimum interval check = 4 hours between reminders (Section 6)
        if (history.length > 0) {
          const lastSentMs = new Date(history[0].sent_at).getTime();
          const hoursSinceLast = (nowMs - lastSentMs) / (1000 * 60 * 60);
          if (hoursSinceLast < 4) {
            continue;
          }
        }

        const nextReminderIndex = reminderCount + 1;
        let styleVariant: SpotlightReminderStyle;
        let title: string;
        let body: string;
        let soundVariant: 'spotlight_initial' | 'spotlight_reminder' | 'spotlight_final';

        // Dynamic Rotating Visual Treatment System (Section 3)
        if (nextReminderIndex === 1) {
          styleVariant = 'ALERT';
          soundVariant = 'spotlight_reminder';
          title = 'Your Spotlight is ready';
          body = 'Your turn is waiting. Post your business offer for your network partners.';
        } else if (nextReminderIndex === 2) {
          styleVariant = 'RING';
          soundVariant = 'spotlight_reminder';
          title = 'Ringing for your Spotlight turn';
          body = `Your Spotlight is still waiting — ${timeRemainingHours} hours remaining to share your offer.`;
        } else if (nextReminderIndex === 3) {
          styleVariant = 'PROGRESS';
          soundVariant = 'spotlight_reminder';
          title = 'Spotlight progress update';
          body = `Don't leave your turn unfinished. ${timeRemainingHours}h left to reach your network.`;
        } else {
          styleVariant = 'FINAL_CALL';
          soundVariant = 'spotlight_final';
          title = 'Final call for Spotlight';
          body = `Your turn ends soon! Only ${timeRemainingHours} hours left before your Spotlight expires.`;
        }

        const dedupKey = `SPOTLIGHT_REMINDER:${campaignId}:${userId}:${nextReminderIndex}`;

        const result = await NotificationFoundationService.dispatchEvent({
          recipientUserId: userId,
          eventType: `spotlight.reminder_${styleVariant.toLowerCase()}`,
          source: 'BACKEND',
          deduplicationKey: dedupKey,
          customTitle: title,
          customBody: body,
          customDeepLink: 'bizsquare://spotlight/turn',
          expiresInHours: timeRemainingHours,
        });

        if (result.status === 'SENT') {
          remindersSent++;
          await client.query(`
            INSERT INTO spotlight_reminders_log (user_id, campaign_id, reminder_index, style_variant, dedup_key)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (dedup_key) DO NOTHING
          `, [userId, campaignId, nextReminderIndex, styleVariant, dedupKey]);

          await NotificationFoundationService.trackAnalytics({
            userId,
            eventType: 'spotlight_reminder_sent',
            source: 'BACKEND',
            metadata: { reminderIndex: nextReminderIndex, styleVariant, campaignId, timeRemainingHours },
          });
        }
      }

      return { processedCount: campaigns.length, remindersSent };
    } finally {
      client.release();
    }
  }

  /**
   * CANCEL REMINDERS FOR TURN (Section 5 & 11)
   * Triggered immediately when user submits/fulfills turn.
   */
  static async cancelRemindersForTurn(userId: string, campaignId: string): Promise<void> {
    await pool.query(`
      UPDATE user_notifications
      SET status = 'DISMISSED'
      WHERE user_id = $1 AND dedup_key LIKE $2 AND status = 'SENT'
    `, [userId, `SPOTLIGHT_REMINDER:${campaignId}%`]);

    await pool.query(`
      UPDATE spotlight_reminders_log
      SET status = 'CANCELLED'
      WHERE user_id = $1 AND campaign_id = $2
    `, [userId, campaignId]);

    await NotificationFoundationService.trackAnalytics({
      userId,
      eventType: 'spotlight_notification_cancelled',
      source: 'BACKEND',
      metadata: { campaignId, reason: 'turn_fulfilled' },
    });

    await NotificationFoundationService.trackAnalytics({
      userId,
      eventType: 'spotlight_turn_completed_after_notification',
      source: 'BACKEND',
      metadata: { campaignId },
    });
  }

  /**
   * PARTICIPATION & INTELLIGENT BATCHING (Sections 7 & 8)
   */
  static async recordParticipationAndBatch(params: {
    targetUserId: string;
    actorUserId: string;
    actorName: string;
    campaignId: string;
  }): Promise<void> {
    const { targetUserId, actorUserId, actorName, campaignId } = params;

    // Do not notify self
    if (targetUserId === actorUserId) return;

    const client = await pool.connect();
    try {
      // 1. Insert into batching queue
      await client.query(`
        INSERT INTO spotlight_participation_batch (campaign_id, target_user_id, actor_user_id, actor_name)
        VALUES ($1, $2, $3, $4)
      `, [campaignId, targetUserId, actorUserId, actorName]);

      // 2. Query unprocessed participations in 10-minute window
      const { rows: batch } = await client.query(`
        SELECT actor_name FROM spotlight_participation_batch
        WHERE target_user_id = $1 AND campaign_id = $2 AND processed = FALSE
          AND created_at >= NOW() - INTERVAL '10 minutes'
      `, [targetUserId, campaignId]);

      if (batch.length === 0) return;

      const actorCount = batch.length;
      const windowStr = new Date().toISOString().slice(0, 15); // 10-min key segment
      const dedupKey = `SPOTLIGHT_PARTICIPATION_BATCH:${campaignId}:${targetUserId}:${windowStr}`;

      let title: string;
      let body: string;

      if (actorCount === 1) {
        title = 'Someone just posted for you';
        body = `${batch[0].actor_name} shared your Spotlight offer with their network.`;
      } else if (actorCount === 2) {
        title = '2 people just posted for you';
        body = `${batch[0].actor_name} and ${batch[1].actor_name} shared your Spotlight offer.`;
      } else {
        title = `${actorCount} people just posted for you`;
        body = `${batch[0].actor_name}, ${batch[1].actor_name} and ${actorCount - 2} others shared your Spotlight offer.`;
      }

      const result = await NotificationFoundationService.dispatchEvent({
        recipientUserId: targetUserId,
        eventType: 'spotlight.participation_received',
        source: 'BACKEND',
        deduplicationKey: dedupKey,
        customTitle: title,
        customBody: body,
        customDeepLink: 'bizsquare://spotlight',
      });

      if (result.status === 'SENT') {
        await client.query(`
          UPDATE spotlight_participation_batch
          SET processed = TRUE
          WHERE target_user_id = $1 AND campaign_id = $2 AND processed = FALSE
        `, [targetUserId, campaignId]);

        await NotificationFoundationService.trackAnalytics({
          userId: targetUserId,
          eventType: 'spotlight_participation_received_notification',
          source: 'BACKEND',
          metadata: { actorCount, campaignId },
        });
      }
    } finally {
      client.release();
    }
  }
}
