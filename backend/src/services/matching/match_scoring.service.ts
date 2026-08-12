import { MATCHING_CONFIG } from '../../config/matching.config';
import { 
  UserSupplyProfile, 
  UserStagedDemandProfile, 
  CandidateClassificationResult,
  MatchCandidate
} from '../../types/matching_engine.types';

export class MatchScoringService {
  /**
   * Calculates multi-factor match score within tiers and produces human-readable explanation
   */
  static scoreCandidate(params: {
    userA: UserSupplyProfile;
    candidateB: UserSupplyProfile;
    classification: CandidateClassificationResult;
    demandA: UserStagedDemandProfile;
    isMutual: boolean;
    candidateExposureCount: number;
    userTopicExposureCount: number;
    existingCategoriesInNetwork: Set<string>;
  }): MatchCandidate {
    const {
      userA,
      candidateB,
      classification,
      demandA,
      isMutual,
      candidateExposureCount,
      userTopicExposureCount,
      existingCategoriesInNetwork,
    } = params;

    const baseTierWeight = MATCHING_CONFIG.TIER_BASE_WEIGHTS[classification.tier];
    let score = baseTierWeight;

    // 1. Demand Relevance & Weight
    const demandWeight = classification.matchedInterestWeight || 0.05;
    score += demandWeight * MATCHING_CONFIG.WEIGHTS.DEMAND_RELEVANCE;

    // 2. Demand Confidence & Recency
    const stagedItem = classification.matchedInterestId 
      ? demandA.demandMap.get(classification.matchedInterestId) 
      : null;
    if (stagedItem) {
      score += (stagedItem.confidence || 0.5) * MATCHING_CONFIG.WEIGHTS.DEMAND_CONFIDENCE;
      score += (stagedItem.recencyScore || 1.0) * MATCHING_CONFIG.WEIGHTS.DEMAND_RECENCY;
    }

    // 3. Primary Supply Bonus
    if (classification.matchedSupplyType === 'primary') {
      score += MATCHING_CONFIG.WEIGHTS.SUPPLY_PRIMARY_BONUS;
    }

    // 4. Mutual Match Bonus (B also wants what A offers)
    if (isMutual) {
      score += MATCHING_CONFIG.WEIGHTS.MUTUAL_MATCH_BONUS;
    }

    // 5. Network Diversity Bonus (Adds a new category/niche to user's contact network)
    const offerSlug = candidateB.primaryOfferSlug || candidateB.primaryOfferName;
    if (!existingCategoriesInNetwork.has(offerSlug.toLowerCase())) {
      score += MATCHING_CONFIG.WEIGHTS.DIVERSITY_BONUS;
    }

    // 6. Candidate Exposure Penalty (Soft penalty for heavily exposed suppliers across network)
    const exposurePenalty = Math.min(25.0, candidateExposureCount * MATCHING_CONFIG.WEIGHTS.EXPOSURE_PENALTY_FACTOR);
    score -= exposurePenalty;

    // 7. Saturation Penalty (User already has multiple contacts in this specific niche)
    const saturationPenalty = Math.min(20.0, userTopicExposureCount * MATCHING_CONFIG.WEIGHTS.SATURATION_PENALTY_FACTOR);
    score -= saturationPenalty;

    // Clamp score
    score = Math.max(0.1, parseFloat(score.toFixed(3)));

    // Generate human-readable match explanation text
    let explanationText = '';
    if (classification.tier === 'TIER_1') {
      explanationText = `Matched because ${candidateB.businessName} primarily offers ${candidateB.primaryOfferName}, which aligns with your top interest.`;
    } else if (classification.tier === 'TIER_2') {
      explanationText = `Matched because ${candidateB.businessName} offers ${classification.matchedInterestSlug || 'relevant services'} matching what you recently explored.`;
    } else {
      explanationText = `Introduced to expand your verified contact network with ${candidateB.businessName} (${candidateB.primaryOfferName}).`;
    }

    if (isMutual) {
      explanationText += ` They also showed mutual demand for your offerings.`;
    }

    return {
      candidateId: candidateB.userId,
      tier: classification.tier,
      matchReason: classification.matchReason,
      matchedInterestId: classification.matchedInterestId,
      matchedInterestSlug: classification.matchedInterestSlug,
      matchedInterestWeight: demandWeight,
      matchedSupplyId: classification.matchedSupplyId,
      matchedSupplyType: classification.matchedSupplyType,
      isMutual,
      score,
      candidateSupply: candidateB,
      explanationText,
    };
  }
}
