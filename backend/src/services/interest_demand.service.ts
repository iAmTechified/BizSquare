import { pool } from '../db/pool';
import { UserCurrentDemandItem, UserCurrentDemandOutput } from '../types/interest_engine.types';

export class InterestDemandService {
  /**
   * Generates concentrated Current Demand output payload for a user
   */
  static async getCurrentDemand(userId: string): Promise<UserCurrentDemandOutput> {
    // 1. Fetch dynamic interest states with taxonomy details
    const stateQuery = `
      SELECT 
        uis.taxonomy_id, t.slug, t.name, t.context_type,
        uis.state, uis.strength, uis.confidence, uis.recency_score,
        uis.frequency_count, uis.last_positive_at,
        EXISTS(SELECT 1 FROM user_baseline_interests ubi WHERE ubi.user_id = $1 AND ubi.taxonomy_id = uis.taxonomy_id) as is_baseline
      FROM user_interest_states uis
      JOIN interest_taxonomies t ON t.id = uis.taxonomy_id
      WHERE uis.user_id = $1
      ORDER BY uis.strength DESC, uis.confidence DESC
    `;
    const { rows: stateRows } = await pool.query(stateQuery, [userId]);

    // 2. Fetch baseline interests that might not have dynamic events yet
    const baselineOnlyQuery = `
      SELECT 
        ubi.taxonomy_id, t.slug, t.name, t.context_type,
        'ACTIVE' as state, 0.500 as strength, 0.400 as confidence, 1.000 as recency_score,
        1 as frequency_count, ubi.created_at as last_positive_at,
        TRUE as is_baseline
      FROM user_baseline_interests ubi
      JOIN interest_taxonomies t ON t.id = ubi.taxonomy_id
      WHERE ubi.user_id = $1 
        AND ubi.taxonomy_id NOT IN (SELECT taxonomy_id FROM user_interest_states WHERE user_id = $1)
    `;
    const { rows: baselineRows } = await pool.query(baselineOnlyQuery, [userId]);

    const allItems: UserCurrentDemandItem[] = [...stateRows, ...baselineRows].map(r => ({
      taxonomy_id: r.taxonomy_id,
      slug: r.slug,
      name: r.name,
      context_type: r.context_type,
      state: r.state,
      strength: Number(r.strength),
      confidence: Number(r.confidence),
      recency_score: Number(r.recency_score),
      frequency_count: Number(r.frequency_count),
      last_positive_at: r.last_positive_at,
      is_baseline: Boolean(r.is_baseline),
    }));

    // Tier Segmentation
    const demand_tier_high: UserCurrentDemandItem[] = [];
    const demand_tier_medium: UserCurrentDemandItem[] = [];
    const demand_tier_emerging: UserCurrentDemandItem[] = [];
    const background_interests: UserCurrentDemandItem[] = [];
    const dormant_interests: UserCurrentDemandItem[] = [];

    allItems.forEach(item => {
      if (item.state === 'SUPPRESSED') {
        return; // Suppressed interests excluded from current demand
      } else if (item.state === 'DORMANT') {
        dormant_interests.push(item);
      } else if (item.state === 'EMERGING') {
        demand_tier_emerging.push(item);
      } else if (item.strength >= 0.70 || (item.is_baseline && item.strength >= 0.50)) {
        demand_tier_high.push(item);
      } else if (item.strength >= 0.40) {
        demand_tier_medium.push(item);
      } else {
        background_interests.push(item);
      }
    });

    return {
      user_id: userId,
      calculated_at: new Date().toISOString(),
      demand_tier_high,
      demand_tier_medium,
      demand_tier_emerging,
      background_interests,
      dormant_interests,
    };
  }

  /**
   * Sets/replaces baseline interests for a user (Profile -> Interests -> My Interests)
   */
  static async setBaselineInterests(userId: string, taxonomyIds: string[]): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Delete existing baseline
      await client.query('DELETE FROM user_baseline_interests WHERE user_id = $1', [userId]);

      if (taxonomyIds.length > 0) {
        const values: any[] = [];
        const placeholders: string[] = [];

        taxonomyIds.forEach((tId, i) => {
          placeholders.push(`($1, $${i + 2})`);
          values.push(tId);
        });

        const insertQuery = `
          INSERT INTO user_baseline_interests (user_id, taxonomy_id)
          VALUES ${placeholders.join(', ')}
          ON CONFLICT (user_id, taxonomy_id) DO NOTHING
        `;
        await client.query(insertQuery, [userId, ...values]);
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Get user baseline interests
   */
  static async getBaselineInterests(userId: string): Promise<{ id: string; slug: string; name: string; icon: string }[]> {
    const query = `
      SELECT t.id, t.slug, t.name, t.icon
      FROM user_baseline_interests ubi
      JOIN interest_taxonomies t ON t.id = ubi.taxonomy_id
      WHERE ubi.user_id = $1
      ORDER BY t.name ASC
    `;
    const { rows } = await pool.query(query, [userId]);
    return rows;
  }
}
