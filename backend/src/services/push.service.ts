import { initializeApp, getApps, App, cert, applicationDefault } from 'firebase-admin/app';
import { getMessaging, Message, BatchResponse } from 'firebase-admin/messaging';
import { pool } from '../db/pool';
import { PushTokenService } from './push_token.service';

/**
 * Initializes Firebase Admin SDK (singleton, lazy).
 * Supports:
 *   - FIREBASE_SERVICE_ACCOUNT_JSON env var (JSON blob for Render/Railway)
 *   - GOOGLE_APPLICATION_CREDENTIALS file path
 */
function getFirebaseApp(): App {
  if (getApps().length > 0) {
    return getApps()[0];
  }

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    try {
      const serviceAccount = JSON.parse(serviceAccountJson);
      return initializeApp({ credential: cert(serviceAccount) });
    } catch (err) {
      console.error('[PushService] Invalid FIREBASE_SERVICE_ACCOUNT_JSON:', err);
    }
  }

  // Fallback to GOOGLE_APPLICATION_CREDENTIALS
  return initializeApp({ credential: applicationDefault() });
}

export interface PushPayload {
  title: string;
  body: string;
  deepLink?: string;
  data?: Record<string, string>;
  priority?: 'ACTION_REQUIRED' | 'IMPORTANT_UPDATE' | 'INFORMATIONAL';
  notificationId?: string;
}

/**
 * Production FCM push delivery using firebase-admin v12+ modular API.
 * Handles multi-device users, token expiry, delivery logging, and analytics.
 */
export class PushService {
  /**
   * Sends a push notification to all active devices for a user.
   */
  static async sendToUser(params: {
    userId: string;
    notificationId: string;
    payload: PushPayload;
  }): Promise<{ sent: number; failed: number }> {
    const { userId, notificationId, payload } = params;

    const tokens = await PushTokenService.getActiveTokens(userId);
    if (tokens.length === 0) {
      return { sent: 0, failed: 0 };
    }

    let app: App;
    try {
      app = getFirebaseApp();
    } catch (initErr) {
      // Firebase not configured in this environment — skip push gracefully
      console.warn('[PushService] Firebase not configured. Push skipped. Set FIREBASE_SERVICE_ACCOUNT_JSON to enable push.');
      return { sent: 0, failed: 0 };
    }

    const messaging = getMessaging(app);
    const isHighPriority = payload.priority === 'ACTION_REQUIRED';

    const messages: Message[] = tokens.map(token => ({
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        notificationId,
        deepLink: payload.deepLink || '',
        priority: payload.priority || 'INFORMATIONAL',
        ...(payload.data || {}),
      },
      android: {
        priority: isHighPriority ? 'high' : 'normal',
        notification: {
          channelId: PushService._getChannelId(payload.priority),
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
        headers: {
          'apns-priority': isHighPriority ? '10' : '5',
        },
      },
    }));

    let sent = 0;
    let failed = 0;

    let batchResponse: BatchResponse;
    try {
      batchResponse = await messaging.sendEach(messages);
    } catch (fcmErr) {
      console.error('[PushService] FCM sendEach error:', fcmErr);
      return { sent: 0, failed: tokens.length };
    }

    for (let i = 0; i < batchResponse.responses.length; i++) {
      const resp = batchResponse.responses[i];
      const token = tokens[i];

      if (resp.success) {
        sent++;
        await PushService._logDelivery({ notificationId, userId, token, status: 'sent' });
      } else {
        failed++;
        const errorCode = resp.error?.code || '';
        const isExpired =
          errorCode === 'messaging/registration-token-not-registered' ||
          errorCode === 'messaging/invalid-registration-token';

        if (isExpired) {
          await PushTokenService.expireToken(token);
        }

        await PushService._logDelivery({
          notificationId,
          userId,
          token,
          status: 'failed',
          failureReason: resp.error?.message || errorCode,
        });
      }
    }

    if (sent > 0) {
      await pool.query(
        `UPDATE user_notifications SET push_sent = TRUE WHERE id = $1`,
        [notificationId]
      );
    }

    return { sent, failed };
  }

  /**
   * Records that a push notification was opened by the user.
   */
  static async recordOpened(notificationId: string): Promise<void> {
    try {
      await pool.query(`
        UPDATE push_delivery_log
        SET opened_at = CURRENT_TIMESTAMP, status = 'delivered'
        WHERE notification_id = $1 AND status = 'sent'
      `, [notificationId]);
    } catch (_) {}
  }

  private static async _logDelivery(params: {
    notificationId: string;
    userId: string;
    token: string;
    status: string;
    failureReason?: string;
  }): Promise<void> {
    try {
      await pool.query(`
        INSERT INTO push_delivery_log (notification_id, user_id, token, status, sent_at, failure_reason)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, $5)
        ON CONFLICT DO NOTHING
      `, [params.notificationId, params.userId, params.token, params.status, params.failureReason || null]);
    } catch (_) {}
  }

  private static _getChannelId(priority?: string): string {
    switch (priority) {
      case 'ACTION_REQUIRED': return 'bizsquare_action_required';
      case 'IMPORTANT_UPDATE': return 'bizsquare_important';
      default: return 'bizsquare_general';
    }
  }
}
