import { pool } from '../db/pool';

export class PollsService {
  /**
   * Retrieves a batch of 10 unswiped scenario cards for the user.
   */
  static async getActivePolls(userId: string) {
    const { rows } = await pool.query(
      `SELECT p.* 
       FROM scenario_polls p
       WHERE p.is_active = true 
         AND NOT EXISTS (
           SELECT 1 FROM user_poll_responses upr 
           WHERE upr.poll_id = p.id AND upr.user_id = $1
         )
       ORDER BY RANDOM()
       LIMIT 10`,
      [userId]
    );
    return rows;
  }

  /**
   * Submits a left/right swipe boolean. Updates user_poll_responses.
   */
  static async submitSwipe(userId: string, pollId: string, response: boolean) {
    const { rows } = await pool.query(
      `INSERT INTO user_poll_responses (user_id, poll_id, response)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, poll_id) 
       DO UPDATE SET response = EXCLUDED.response, created_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [userId, pollId, response]
    );
    return rows[0];
  }
}
