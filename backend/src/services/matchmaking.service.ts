import { pool } from '../db/pool';
import { NotificationEvents } from './notification.service';

export class MatchmakingService {
  /**
   * Executes the weekly matchmaking batch.
   * Rules enforced:
   * 1. 10% Volume Cap: A user receives a contact batch no larger than 10% of the active network.
   * 2. Micro-Niche Collision: ANY shared micro-niche between two businesses = DENY.
   *    Sharing a broad CATEGORY does NOT create a collision.
   * 3. Demand Prioritization: Dynamic Demand (14-day window) → Baseline Demand.
   * 4. Akawo Points: Demand (user_a) spends 1 pt to receive a match; Supply (user_b) earns 1 pt.
   */
  static async runWeeklyMatchmaking() {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Get total active users to calculate the 10% volume cap
      const { rows: [{ count }] } = await client.query(
        `SELECT COUNT(*) FROM users WHERE is_active = true AND onboarding_completed = true`
      );
      const totalUsers = parseInt(count, 10);
      const volumeCap = Math.max(1, Math.floor(totalUsers * 0.10));

      // Track points in-memory during this matchmaking batch
      const { rows: usersData } = await client.query(
        `SELECT id, akawo_points FROM users WHERE is_active = true AND onboarding_completed = true`
      );
      const pointsMap = new Map<string, number>();
      for (const u of usersData) {
        pointsMap.set(u.id, u.akawo_points);
      }

      // 2. Fetch all eligible pairs with NO micro-niche collision
      // COLLISION RULE: ANY shared micro_niche_id between two users = DENY
      // IMPORTANT: Sharing a broad category does NOT create a collision
      const eligiblePairsQuery = `
        SELECT u1.id AS user_a, u2.id AS user_b
        FROM users u1
        JOIN users u2 ON u1.id != u2.id
        WHERE u1.is_active = true AND u1.onboarding_completed = true
          AND u2.is_active = true AND u2.onboarding_completed = true
          -- No micro-niche collision: DENY if ANY shared micro-niche
          AND NOT EXISTS (
            SELECT 1 FROM business_micro_niches bm1
            JOIN business_micro_niches bm2 ON bm1.micro_niche_id = bm2.micro_niche_id
            WHERE bm1.user_id = u1.id AND bm2.user_id = u2.id
          )
          -- Not already matched
          AND NOT EXISTS (
            SELECT 1 FROM matches m
            WHERE m.user_a_id = u1.id AND m.user_b_id = u2.id
          )
        ORDER BY RANDOM();
      `;

      const { rows: potentialPairs } = await client.query(eligiblePairsQuery);

      // 3. Score each pair by demand overlap
      // Priority: Dynamic Demand (unexpired) > Baseline Demand
      const scoredPairs: { user_a: string; user_b: string; score: number }[] = [];

      for (const pair of potentialPairs) {
        const { user_a, user_b } = pair;

        // Get user_a's demand (what they want) and check if user_b supplies it
        const { rows: demandScore } = await client.query(`
          WITH user_demand AS (
            -- Dynamic demand (higher priority, weight = 2)
            SELECT micro_niche_id, 2.0 * strength AS weight
            FROM dynamic_demand
            WHERE user_id = $1
              AND expires_at > CURRENT_TIMESTAMP
              AND interaction_type = 'positive'
            UNION ALL
            -- Baseline demand (lower priority, weight = 1)
            SELECT micro_niche_id, 1.0 AS weight
            FROM baseline_demand
            WHERE user_id = $1 AND is_active = TRUE
          )
          SELECT COALESCE(SUM(ud.weight), 0) AS total_score
          FROM user_demand ud
          JOIN business_micro_niches bm ON bm.micro_niche_id = ud.micro_niche_id
          WHERE bm.user_id = $2
        `, [user_a, user_b]);

        const score = parseFloat(demandScore[0].total_score);
        scoredPairs.push({ ...pair, score });
      }

      // Sort by demand score descending (highest demand matches first)
      scoredPairs.sort((a, b) => b.score - a.score);

      const userMatchCounts = new Map<string, number>();
      const finalMatches: { user_a: string; user_b: string }[] = [];

      for (const pair of scoredPairs) {
        const { user_a, user_b } = pair;
        const countA = userMatchCounts.get(user_a) || 0;
        const countB = userMatchCounts.get(user_b) || 0;
        const pointsA = pointsMap.get(user_a) || 0;

        // Demand MUST have > 0 points to spend
        if (countA < volumeCap && countB < volumeCap && pointsA > 0) {
          finalMatches.push({ user_a, user_b });

          userMatchCounts.set(user_a, countA + 1);
          userMatchCounts.set(user_b, countB + 1);

          // Demand spends 1, Supply earns 1
          pointsMap.set(user_a, pointsA - 1);
          pointsMap.set(user_b, (pointsMap.get(user_b) || 0) + 1);
        }
      }

      // 4. Batch insert the new matches and ledger entries
      if (finalMatches.length > 0) {
        const matchValues = finalMatches.map((_, i) =>
          `($${i * 2 + 1}, $${i * 2 + 2}, CURRENT_DATE)`
        ).join(', ');
        const flatParams = finalMatches.flatMap(m => [m.user_a, m.user_b]);

        await client.query(`
          INSERT INTO matches (user_a_id, user_b_id, batch_date)
          VALUES ${matchValues}
        `, flatParams);

        // Insert ledger entries
        const ledgerEntries: { userId: string; points: number; type: string }[] = [];
        for (const m of finalMatches) {
          ledgerEntries.push({ userId: m.user_a, points: -1, type: 'match_demand' });
          ledgerEntries.push({ userId: m.user_b, points: 1, type: 'match_supply' });
        }

        const ledgerValues = ledgerEntries.map((_, i) =>
          `($${i * 3 + 1}, $${i * 3 + 2}, $${i * 3 + 3})`
        ).join(', ');
        const ledgerParams = ledgerEntries.flatMap(e => [e.userId, e.points, e.type]);

        await client.query(`
          INSERT INTO akawo_ledger (user_id, points_awarded, transaction_type)
          VALUES ${ledgerValues}
        `, ledgerParams);
      }

      await client.query('COMMIT');

      // Fire CONTACT_GAIN_READY notification per user with their actual contact count.
      // Dedup key includes batchDate so only one notification fires per weekly cycle.
      const batchDate = new Date().toISOString().slice(0, 10);
      setImmediate(async () => {
        for (const [userId, matchCount] of userMatchCounts.entries()) {
          if (matchCount > 0) {
            try {
              await NotificationEvents.contactGainReady({
                userId,
                contactCount: matchCount,
                cycleId: batchDate,
                batchDate,
              });
            } catch (notifErr) {
              console.error(`[Matchmaking] Notification failed for user ${userId}:`, notifErr);
            }
          }
        }
      });

      return {
        success: true,
        matchesCreated: finalMatches.length,
        capPerUser: volumeCap,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Matchmaking failed:', error);
      throw error;
    } finally {
      client.release();
    }
  }
}
