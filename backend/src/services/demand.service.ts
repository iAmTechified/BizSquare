import { pool } from '../db/pool';

export class DemandService {
  /**
   * Creates baseline demand entries from onboarding Step 5 interests.
   * Up to 5 micro-niche IDs.
   */
  static async createBaselineDemand(userId: string, microNicheIds: string[]) {
    if (microNicheIds.length === 0 || microNicheIds.length > 5) {
      throw new Error('Must select between 1 and 5 interests');
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Clear existing baseline demand for this user
      await client.query(`DELETE FROM baseline_demand WHERE user_id = $1`, [userId]);

      // Insert new baseline demand
      const values = microNicheIds.map((_, i) => `($1, $${i + 2}, 'onboarding', TRUE)`).join(', ');
      await client.query(
        `INSERT INTO baseline_demand (user_id, micro_niche_id, source, is_active) VALUES ${values}
         ON CONFLICT (user_id, micro_niche_id) DO UPDATE SET is_active = TRUE, source = 'onboarding'`,
        [userId, ...microNicheIds]
      );

      await client.query('COMMIT');
      return { success: true, count: microNicheIds.length };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Creates a dynamic demand signal from Daily Wall interaction.
   * Positive interactions have strength 1.0, negatives 0.0.
   * Expires in ~14 days.
   */
  static async createDynamicDemand(
    userId: string,
    microNicheId: string,
    interactionType: 'positive' | 'negative' | 'skip'
  ) {
    const strength = interactionType === 'positive' ? 1.0 : 0.0;

    const { rows } = await pool.query(
      `INSERT INTO dynamic_demand (user_id, micro_niche_id, source, interaction_type, strength, expires_at)
       VALUES ($1, $2, 'daily_wall', $3, $4, CURRENT_TIMESTAMP + INTERVAL '14 days')
       RETURNING *`,
      [userId, microNicheId, interactionType, strength]
    );
    return rows[0];
  }

  /**
   * Gets active demand for a user (both dynamic unexpired + baseline).
   */
  static async getActiveDemand(userId: string) {
    const { rows: dynamicDemand } = await pool.query(
      `SELECT dd.id, dd.micro_niche_id, mn.name AS micro_niche_name,
              dd.source, dd.interaction_type, dd.strength, dd.created_at, dd.expires_at
       FROM dynamic_demand dd
       JOIN micro_niches mn ON mn.id = dd.micro_niche_id
       WHERE dd.user_id = $1
         AND dd.expires_at > CURRENT_TIMESTAMP
         AND dd.interaction_type = 'positive'
       ORDER BY dd.strength DESC, dd.created_at DESC`,
      [userId]
    );

    const { rows: baselineDemand } = await pool.query(
      `SELECT bd.id, bd.micro_niche_id, mn.name AS micro_niche_name,
              bd.source, bd.created_at
       FROM baseline_demand bd
       JOIN micro_niches mn ON mn.id = bd.micro_niche_id
       WHERE bd.user_id = $1 AND bd.is_active = TRUE
       ORDER BY bd.created_at`,
      [userId]
    );

    return { dynamicDemand, baselineDemand };
  }

  /**
   * Cleanup expired dynamic demand (cron job).
   */
  static async cleanupExpiredDemand() {
    const { rowCount } = await pool.query(
      `DELETE FROM dynamic_demand WHERE expires_at < CURRENT_TIMESTAMP`
    );
    return { removed: rowCount };
  }
}
