import { pool } from '../db/pool';

export class MatchingAnalyticsService {
  /**
   * Returns network-level matching KPIs and analytics
   */
  static async getMatchingAnalytics() {
    // 1. Cycle summaries
    const cycleQuery = `
      SELECT 
        COUNT(*) as total_cycles,
        COALESCE(SUM(total_allocations), 0) as total_contacts_allocated,
        COALESCE(SUM(tier_1_count), 0) as total_tier_1,
        COALESCE(SUM(tier_2_count), 0) as total_tier_2,
        COALESCE(SUM(tier_3_count), 0) as total_tier_3,
        COALESCE(SUM(competitor_exclusions_count), 0) as total_competitor_exclusions,
        COALESCE(AVG(execution_duration_ms), 0) as avg_duration_ms
      FROM weekly_matching_cycles
      WHERE status = 'COMPLETED'
    `;
    const { rows: [cycleStats] } = await pool.query(cycleQuery);

    // 2. Active network size
    const { rows: [userStats] } = await pool.query(`
      SELECT COUNT(*) as active_users FROM users WHERE is_active = TRUE AND onboarding_completed = TRUE
    `);

    // 3. Top supplied niches in the network
    const supplyQuery = `
      SELECT mn.name as niche_name, COUNT(bmn.user_id) as supplier_count
      FROM business_micro_niches bmn
      JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
      WHERE bmn.is_primary = TRUE
      GROUP BY mn.name
      ORDER BY supplier_count DESC
      LIMIT 6
    `;
    const { rows: topSupply } = await pool.query(supplyQuery);

    // 4. Most exposed suppliers in recent matching cycles
    const exposureQuery = `
      SELECT 
        u.id as user_id,
        u.business_name,
        mn.name as primary_offer,
        COUNT(ma.id) as total_received_connections
      FROM match_allocations ma
      JOIN users u ON u.id = ma.candidate_user_id
      JOIN business_micro_niches bmn ON bmn.user_id = u.id AND bmn.is_primary = TRUE
      JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
      GROUP BY u.id, u.business_name, mn.name
      ORDER BY total_received_connections DESC
      LIMIT 6
    `;
    const { rows: topExposed } = await pool.query(exposureQuery);

    // 5. Recent 5 cycles
    const recentCyclesQuery = `
      SELECT * FROM weekly_matching_cycles
      ORDER BY created_at DESC
      LIMIT 10
    `;
    const { rows: recentCycles } = await pool.query(recentCyclesQuery);

    return {
      activeNetworkSize: parseInt(userStats.active_users, 10),
      totalCycles: parseInt(cycleStats.total_cycles, 10),
      totalContactsAllocated: parseInt(cycleStats.total_contacts_allocated, 10),
      tierDistribution: {
        tier1: parseInt(cycleStats.total_tier_1, 10),
        tier2: parseInt(cycleStats.total_tier_2, 10),
        tier3: parseInt(cycleStats.total_tier_3, 10),
      },
      totalCompetitorExclusions: parseInt(cycleStats.total_competitor_exclusions, 10),
      avgDurationMs: Math.round(parseFloat(cycleStats.avg_duration_ms)),
      topSupplyCategories: topSupply.map(r => ({
        niche: r.niche_name,
        count: parseInt(r.supplier_count, 10),
      })),
      mostExposedSuppliers: topExposed.map(r => ({
        userId: r.user_id,
        businessName: r.business_name,
        primaryOffer: r.primary_offer,
        connections: parseInt(r.total_received_connections, 10),
      })),
      recentCycles: recentCycles.map(c => ({
        id: c.id,
        cycleNumber: c.cycle_number,
        batchDate: c.batch_date,
        networkSize: c.network_size,
        targetPerUser: c.target_per_user,
        status: c.status,
        usersProcessed: c.users_processed,
        usersFilled: c.users_filled,
        usersUnderfilled: c.users_underfilled,
        totalAllocations: c.total_allocations,
        tier1Count: c.tier_1_count,
        tier2Count: c.tier_2_count,
        tier3Count: c.tier_3_count,
        competitorExclusionsCount: c.competitor_exclusions_count,
        executionDurationMs: c.execution_duration_ms,
        createdAt: c.created_at,
      })),
    };
  }

  /**
   * Fetches detailed allocations and user summaries for a specific cycle
   */
  static async getCycleDetails(cycleId: string) {
    const { rows: [cycle] } = await pool.query(
      `SELECT * FROM weekly_matching_cycles WHERE id = $1`,
      [cycleId]
    );

    if (!cycle) return null;

    const { rows: userSummaries } = await pool.query(
      `SELECT cas.*, u.business_name 
       FROM cycle_allocation_summaries cas
       JOIN users u ON u.id = cas.user_id
       WHERE cas.cycle_id = $1
       ORDER BY cas.allocated_count DESC`,
      [cycleId]
    );

    return {
      cycle,
      userSummaries,
    };
  }

  /**
   * Fetches user match history with full explainability text
   */
  static async getUserMatchHistory(userId: string) {
    const query = `
      SELECT 
        mh.*,
        u_cand.business_name as candidate_business_name,
        u_cand.phone_number as candidate_phone,
        u_cand.avatar_id as candidate_avatar
      FROM match_history mh
      JOIN users u_cand ON u_cand.id = mh.user_b
      WHERE mh.user_a = $1
      ORDER BY mh.created_at DESC
      LIMIT 50
    `;
    const { rows } = await pool.query(query, [userId]);
    return rows;
  }
}
