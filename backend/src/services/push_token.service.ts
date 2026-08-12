import { pool } from '../db/pool';

/**
 * Manages FCM push tokens per user/device.
 * One token per device. A user may have multiple devices.
 */
export class PushTokenService {
  /**
   * Registers or refreshes an FCM push token for a user.
   * Handles the case where the token was previously registered to another user
   * (e.g. device transferred) by deactivating the old registration.
   */
  static async registerToken(params: {
    userId: string;
    token: string;
    platform?: 'android' | 'ios';
  }): Promise<void> {
    const { userId, token, platform = 'android' } = params;

    // Deactivate any previous registration of this token under a different user
    await pool.query(`
      UPDATE push_tokens
      SET is_active = FALSE
      WHERE token = $1 AND user_id != $2
    `, [token, userId]);

    // Upsert: register or refresh
    await pool.query(`
      INSERT INTO push_tokens (user_id, token, platform, registered_at, last_used_at, is_active)
      VALUES ($1, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, TRUE)
      ON CONFLICT (token) DO UPDATE
        SET user_id = EXCLUDED.user_id,
            platform = EXCLUDED.platform,
            last_used_at = CURRENT_TIMESTAMP,
            is_active = TRUE
    `, [userId, token, platform]);
  }

  /**
   * Deregisters all push tokens for a user (e.g. on logout).
   * Optionally deactivates only a specific token.
   */
  static async deregisterToken(params: {
    userId: string;
    token?: string;
  }): Promise<void> {
    const { userId, token } = params;
    if (token) {
      await pool.query(`
        UPDATE push_tokens SET is_active = FALSE
        WHERE user_id = $1 AND token = $2
      `, [userId, token]);
    } else {
      await pool.query(`
        UPDATE push_tokens SET is_active = FALSE WHERE user_id = $1
      `, [userId]);
    }
  }

  /**
   * Retrieves all active FCM tokens for a user (across all devices).
   */
  static async getActiveTokens(userId: string): Promise<string[]> {
    const { rows } = await pool.query(`
      SELECT token FROM push_tokens
      WHERE user_id = $1 AND is_active = TRUE
    `, [userId]);
    return rows.map((r: any) => r.token);
  }

  /**
   * Marks a specific token as expired/invalid (called after FCM returns 404/410).
   */
  static async expireToken(token: string): Promise<void> {
    await pool.query(`
      UPDATE push_tokens SET is_active = FALSE
      WHERE token = $1
    `, [token]);
  }
}
