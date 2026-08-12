/**
 * Centralized Configuration for BizSquare Matching Engine
 * All business weights, volume caps, thresholds, and penalties are managed here.
 */
export const MATCHING_CONFIG = {
  // Weekly Volume Rules
  WEEKLY_ALLOCATION_PERCENTAGE: 0.10, // 10% of active eligible network
  MAX_ALLOCATION_PERCENTAGE: 0.10,
  MIN_WEEKLY_TARGET: 1,

  // Tier Base Scoring Priority (Tier 1 > Tier 2 > Tier 3)
  TIER_BASE_WEIGHTS: {
    TIER_1: 1000.0, // Primary Supply Match
    TIER_2: 500.0,  // Secondary Supply Match
    TIER_3: 100.0,  // Fallback Network Expansion
  },

  // Scoring Weights within Tier
  WEIGHTS: {
    DEMAND_RELEVANCE: 40.0,     // Staged demand percentage weight
    DEMAND_CONFIDENCE: 20.0,    // Staged demand confidence scaling
    DEMAND_RECENCY: 15.0,       // Demand freshness/recency score
    MUTUAL_MATCH_BONUS: 25.0,   // Bonus when B also wants something A offers (B -> A)
    SUPPLY_PRIMARY_BONUS: 15.0, // Bonus for Primary offer supply
    DIVERSITY_BONUS: 15.0,      // Bonus when candidate adds a new category to user's network
    EXPOSURE_PENALTY_FACTOR: 0.25, // Soft penalty for overly-exposed suppliers
    SATURATION_PENALTY_FACTOR: 0.20, // Soft penalty if user already has many contacts in this topic
  },

  // History & Cooldowns
  PREVIOUS_MATCH_COOLDOWN_DAYS: 30,
  REMOVED_CONTACT_COOLDOWN_DAYS: 60,

  // Calculation helper for 10% target
  calculateWeeklyTarget(networkSize: number): number {
    return Math.max(this.MIN_WEEKLY_TARGET, Math.floor(networkSize * this.WEEKLY_ALLOCATION_PERCENTAGE));
  },
};
