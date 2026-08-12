import { pool } from '../../db/pool';
import { InterestDemandService } from '../interest_demand.service';
import { StagedDemandItem, UserStagedDemandProfile } from '../../types/matching_engine.types';

export class StagedDemandService {
  /**
   * Generates staged demand profiles for all eligible network users.
   * Converts raw interest states and baseline selections into normalized relative demand weights (summing to 1.0).
   */
  static async loadAllStagedDemands(userIds: string[]): Promise<Map<string, UserStagedDemandProfile>> {
    const demandMap = new Map<string, UserStagedDemandProfile>();

    // Also fetch micro-niche baseline demand if users have older onboarding data
    const legacyDemandQuery = `
      SELECT bd.user_id, bd.micro_niche_id, mn.name as niche_name
      FROM baseline_demand bd
      JOIN micro_niches mn ON mn.id = bd.micro_niche_id
      WHERE bd.user_id = ANY($1) AND bd.is_active = TRUE
    `;
    const { rows: legacyRows } = await pool.query(legacyDemandQuery, [userIds]);
    const legacyMap = new Map<string, { id: string; name: string }[]>();
    for (const r of legacyRows) {
      if (!legacyMap.has(r.user_id)) legacyMap.set(r.user_id, []);
      legacyMap.get(r.user_id)!.push({ id: r.micro_niche_id, name: r.niche_name });
    }

    for (const userId of userIds) {
      const demandOutput = await InterestDemandService.getCurrentDemand(userId);
      const rawCandidates = [
        ...demandOutput.demand_tier_high,
        ...demandOutput.demand_tier_medium,
        ...demandOutput.demand_tier_emerging,
      ];

      const stagedItems: StagedDemandItem[] = [];
      let totalRawScore = 0;

      for (const item of rawCandidates) {
        // Raw score combines strength, confidence, and recency
        const score = (item.strength * 0.5) + (item.confidence * 0.3) + (item.recency_score * 0.2);
        totalRawScore += score;
      }

      if (totalRawScore > 0) {
        for (const item of rawCandidates) {
          const score = (item.strength * 0.5) + (item.confidence * 0.3) + (item.recency_score * 0.2);
          const weightPercentage = parseFloat((score / totalRawScore).toFixed(4));
          stagedItems.push({
            taxonomyId: item.taxonomy_id,
            slug: item.slug,
            name: item.name,
            weightPercentage,
            confidence: item.confidence,
            recencyScore: item.recency_score,
            isBaseline: item.is_baseline,
          });
        }
      }

      // If user has legacy micro-niche baseline demand, add them as well
      const legList = legacyMap.get(userId) || [];
      if (legList.length > 0 && stagedItems.length === 0) {
        const legWeight = parseFloat((1.0 / legList.length).toFixed(4));
        for (const leg of legList) {
          stagedItems.push({
            taxonomyId: leg.id,
            slug: leg.name.toLowerCase().replace(/\s+/g, '_'),
            name: leg.name,
            weightPercentage: legWeight,
            confidence: 0.5,
            recencyScore: 1.0,
            isBaseline: true,
          });
        }
      }

      // Sort by weight descending
      stagedItems.sort((a, b) => b.weightPercentage - a.weightPercentage);

      const profileMap = new Map<string, StagedDemandItem>();
      for (const item of stagedItems) {
        profileMap.set(item.taxonomyId, item);
        profileMap.set(item.slug.toLowerCase(), item);
        profileMap.set(item.name.toLowerCase(), item);
      }

      demandMap.set(userId, {
        userId,
        items: stagedItems,
        demandMap: profileMap,
      });
    }

    return demandMap;
  }
}
