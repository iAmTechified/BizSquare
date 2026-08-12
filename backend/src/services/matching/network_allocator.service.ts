import { MATCHING_CONFIG } from '../../config/matching.config';
import { 
  UserSupplyProfile, 
  UserStagedDemandProfile, 
  UserAllocationPlan, 
  MatchCandidate,
  AllocationStatus,
  UnderfillReason
} from '../../types/matching_engine.types';
import { CandidateGeneratorService } from './candidate_generator.service';
import { TierClassifierService } from './tier_classifier.service';
import { MatchScoringService } from './match_scoring.service';

export class NetworkAllocatorService {
  /**
   * Plans weekly allocations across the entire network with global exposure balancing.
   */
  static planNetworkAllocations(params: {
    allUsers: UserSupplyProfile[];
    stagedDemands: Map<string, UserStagedDemandProfile>;
    existingContacts: Set<string>;
  }): { plans: UserAllocationPlan[]; totalCompetitorExclusions: number } {
    const { allUsers, stagedDemands, existingContacts } = params;
    const networkSize = allUsers.length;
    const weeklyTarget = MATCHING_CONFIG.calculateWeeklyTarget(networkSize);

    let totalCompetitorExclusions = 0;

    // Track global exposure (how many times each candidate is allocated this cycle)
    const globalCandidateExposure = new Map<string, number>();

    // Track existing categories per user's existing contacts
    const userNetworkCategories = new Map<string, Set<string>>();
    for (const u of allUsers) {
      userNetworkCategories.set(u.userId, new Set<string>());
    }

    const plans: UserAllocationPlan[] = [];

    for (const userA of allUsers) {
      const demandA = stagedDemands.get(userA.userId) || {
        userId: userA.userId,
        items: [],
        demandMap: new Map(),
      };

      // 1. Generate eligible candidates with hard exclusions
      const { candidates: eligibleList, competitorBlockedCount } = 
        CandidateGeneratorService.generateEligibleCandidates(userA, allUsers, existingContacts);
      
      totalCompetitorExclusions += competitorBlockedCount;

      // 2. Classify and score all eligible candidates
      const scoredCandidates: MatchCandidate[] = [];
      const userCategories = userNetworkCategories.get(userA.userId)!;

      for (const candidateB of eligibleList) {
        const classification = TierClassifierService.classifyCandidate(userA, candidateB, demandA);
        const demandB = stagedDemands.get(candidateB.userId);
        const isMutual = TierClassifierService.checkMutualDemand(userA, candidateB, demandB);

        const candidateExposure = globalCandidateExposure.get(candidateB.userId) || 0;
        const offerSlug = candidateB.primaryOfferSlug || candidateB.primaryOfferName;
        const userTopicCount = userCategories.has(offerSlug.toLowerCase()) ? 1 : 0;

        const candidate = MatchScoringService.scoreCandidate({
          userA,
          candidateB,
          classification,
          demandA,
          isMutual,
          candidateExposureCount: candidateExposure,
          userTopicExposureCount: userTopicCount,
          existingCategoriesInNetwork: userCategories,
        });

        scoredCandidates.push(candidate);
      }

      // 3. Separate by Tier and sort within each tier descending by score
      const tier1Candidates = scoredCandidates
        .filter(c => c.tier === 'TIER_1')
        .sort((a, b) => b.score - a.score);

      const tier2Candidates = scoredCandidates
        .filter(c => c.tier === 'TIER_2')
        .sort((a, b) => b.score - a.score);

      const tier3Candidates = scoredCandidates
        .filter(c => c.tier === 'TIER_3')
        .sort((a, b) => b.score - a.score);

      // 4. Progressive Allocation: Tier 1 -> Tier 2 -> Tier 3
      const allocated: MatchCandidate[] = [];
      let position = 1;

      // Step 1: Allocate Tier 1
      for (const cand of tier1Candidates) {
        if (allocated.length >= weeklyTarget) break;
        allocated.push(cand);
        globalCandidateExposure.set(cand.candidateId, (globalCandidateExposure.get(cand.candidateId) || 0) + 1);
        userCategories.add((cand.candidateSupply.primaryOfferSlug || cand.candidateSupply.primaryOfferName).toLowerCase());
      }

      // Step 2: Allocate Tier 2
      for (const cand of tier2Candidates) {
        if (allocated.length >= weeklyTarget) break;
        allocated.push(cand);
        globalCandidateExposure.set(cand.candidateId, (globalCandidateExposure.get(cand.candidateId) || 0) + 1);
        userCategories.add((cand.candidateSupply.primaryOfferSlug || cand.candidateSupply.primaryOfferName).toLowerCase());
      }

      // Step 3: Allocate Tier 3 (Fallback)
      for (const cand of tier3Candidates) {
        if (allocated.length >= weeklyTarget) break;
        allocated.push(cand);
        globalCandidateExposure.set(cand.candidateId, (globalCandidateExposure.get(cand.candidateId) || 0) + 1);
        userCategories.add((cand.candidateSupply.primaryOfferSlug || cand.candidateSupply.primaryOfferName).toLowerCase());
      }

      // 5. Determine Allocation Status
      let status: AllocationStatus = 'FILLED';
      let underfillReason: UnderfillReason | undefined = undefined;

      if (allocated.length === 0) {
        status = 'NO_ELIGIBLE_SUPPLY';
        underfillReason = competitorBlockedCount > 0 
          ? 'COMPETITOR_COLLISION_RESTRICTION' 
          : 'INSUFFICIENT_ELIGIBLE_SUPPLY';
      } else if (allocated.length < weeklyTarget) {
        status = 'UNDERFILLED';
        underfillReason = 'INSUFFICIENT_ELIGIBLE_SUPPLY';
      }

      const tier1Count = allocated.filter(c => c.tier === 'TIER_1').length;
      const tier2Count = allocated.filter(c => c.tier === 'TIER_2').length;
      const tier3Count = allocated.filter(c => c.tier === 'TIER_3').length;

      plans.push({
        userId: userA.userId,
        targetCount: weeklyTarget,
        allocatedCount: allocated.length,
        tier1Allocated: tier1Count,
        tier2Allocated: tier2Count,
        tier3Allocated: tier3Count,
        status,
        underfillReason,
        allocations: allocated.map((c, i) => ({
          candidateId: c.candidateId,
          tier: c.tier,
          score: c.score,
          position: i + 1,
          matchReason: c.matchReason,
          matchedInterestId: c.matchedInterestId,
          matchedInterestSlug: c.matchedInterestSlug,
          matchedInterestWeight: c.matchedInterestWeight,
          matchedSupplyId: c.matchedSupplyId,
          matchedSupplyType: c.matchedSupplyType,
          isMutual: c.isMutual,
          explanationText: c.explanationText,
        })),
      });
    }

    return { plans, totalCompetitorExclusions };
  }
}
