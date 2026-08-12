"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MatchmakingService = void 0;
const pool_1 = require("../db/pool");
class MatchmakingService {
    /**
     * Executes the weekly matchmaking batch.
     * Rules enforced:
     * 1. 10% Volume Cap: A user receives a contact batch no larger than 10% of the active network.
     * 2. Zero Collision: A user must never be matched with a competitor in their exact same Niche.
     * 3. Mutual Reciprocity: Every pairing must be a two-way street (solved by the undirected graph nature of our DB schema).
     */
    static async runWeeklyMatchmaking() {
        const client = await pool_1.pool.connect();
        try {
            await client.query('BEGIN');
            // 1. Get total active users to calculate the 10% volume cap
            const { rows: [{ count }] } = await client.query(`SELECT COUNT(*) FROM users WHERE is_active = true`);
            const totalUsers = parseInt(count, 10);
            // Ensure the cap is at least 1 for small networks, otherwise 10%
            const volumeCap = Math.max(1, Math.floor(totalUsers * 0.10));
            // 2. Fetch all valid potential pairs
            // - `u1.id < u2.id` enforces we evaluate each pair strictly once (alphabetical/UUID order).
            // - `u1.niche_id != u2.niche_id` enforces Zero Collision.
            // - `NOT EXISTS (...)` enforces we don't repeat historical matches.
            // - `ORDER BY RANDOM()` ensures that matching is fair and distributed.
            const eligiblePairsQuery = `
        SELECT u1.id AS user_a, u2.id AS user_b
        FROM users u1
        JOIN users u2 ON u1.id < u2.id AND u1.niche_id != u2.niche_id
        WHERE u1.is_active = true AND u2.is_active = true
          AND NOT EXISTS (
            SELECT 1 FROM matches m 
            WHERE m.user_a_id = u1.id AND m.user_b_id = u2.id
          )
        ORDER BY RANDOM();
      `;
            const { rows: potentialPairs } = await client.query(eligiblePairsQuery);
            // 3. Greedy algorithm to select pairs respecting the 10% volume cap per user
            const userMatchCounts = new Map();
            const finalMatches = [];
            for (const pair of potentialPairs) {
                const { user_a, user_b } = pair;
                const countA = userMatchCounts.get(user_a) || 0;
                const countB = userMatchCounts.get(user_b) || 0;
                // If BOTH users are strictly under their 10% cap, make the match
                if (countA < volumeCap && countB < volumeCap) {
                    finalMatches.push(pair);
                    userMatchCounts.set(user_a, countA + 1);
                    userMatchCounts.set(user_b, countB + 1);
                }
            }
            // 4. Batch insert the new matches into the Ledger
            if (finalMatches.length > 0) {
                const values = finalMatches.map((_, i) => `($${i * 2 + 1}, $${i * 2 + 2})`).join(', ');
                const flatParams = finalMatches.flatMap(m => [m.user_a, m.user_b]);
                await client.query(`
          INSERT INTO matches (user_a_id, user_b_id)
          VALUES ${values}
        `, flatParams);
            }
            await client.query('COMMIT');
            return {
                success: true,
                matchesCreated: finalMatches.length,
                capPerUser: volumeCap
            };
        }
        catch (error) {
            await client.query('ROLLBACK');
            console.error('Matchmaking failed:', error);
            throw error;
        }
        finally {
            client.release();
        }
    }
}
exports.MatchmakingService = MatchmakingService;
//# sourceMappingURL=matchmaking.service.js.map