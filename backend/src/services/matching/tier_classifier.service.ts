import { 
  UserSupplyProfile, 
  UserStagedDemandProfile, 
  CandidateClassificationResult,
  StagedDemandItem
} from '../../types/matching_engine.types';

export class TierClassifierService {
  /**
   * Helper: checks if a supply offer matches a user's staged demand profile
   */
  private static findDemandMatch(
    offer: { id: string; name: string; slug: string },
    demandProfile: UserStagedDemandProfile
  ): StagedDemandItem | null {
    if (!offer.id) return null;

    // Check by taxonomyId
    if (demandProfile.demandMap.has(offer.id)) {
      return demandProfile.demandMap.get(offer.id)!;
    }

    // Check by slug
    const slugKey = (offer.slug || '').toLowerCase().trim();
    if (slugKey.length > 0 && demandProfile.demandMap.has(slugKey)) {
      return demandProfile.demandMap.get(slugKey)!;
    }

    // Check by name
    const nameKey = (offer.name || '').toLowerCase().trim();
    if (nameKey.length > 0 && demandProfile.demandMap.has(nameKey)) {
      return demandProfile.demandMap.get(nameKey)!;
    }

    return null;
  }

  /**
   * Classifies Candidate B relative to User A's staged demand
   */
  static classifyCandidate(
    userA: UserSupplyProfile,
    candidateB: UserSupplyProfile,
    demandA: UserStagedDemandProfile
  ): CandidateClassificationResult {
    // 1. Check TIER 1: Candidate B's PRIMARY offer matches A's staged demand
    const primaryMatch = this.findDemandMatch(
      {
        id: candidateB.primaryOfferId,
        name: candidateB.primaryOfferName,
        slug: candidateB.primaryOfferSlug,
      },
      demandA
    );

    if (primaryMatch) {
      return {
        tier: 'TIER_1',
        matchReason: 'PRIMARY_SUPPLY_MATCH',
        matchedInterestId: primaryMatch.taxonomyId,
        matchedInterestSlug: primaryMatch.slug,
        matchedInterestWeight: primaryMatch.weightPercentage,
        matchedSupplyId: candidateB.primaryOfferId,
        matchedSupplyType: 'primary',
      };
    }

    // 2. Check TIER 2: Candidate B's SECONDARY offers match A's staged demand
    for (const secOffer of candidateB.secondaryOffers) {
      const secMatch = this.findDemandMatch(secOffer, demandA);
      if (secMatch) {
        return {
          tier: 'TIER_2',
          matchReason: 'SECONDARY_SUPPLY_MATCH',
          matchedInterestId: secMatch.taxonomyId,
          matchedInterestSlug: secMatch.slug,
          matchedInterestWeight: secMatch.weightPercentage,
          matchedSupplyId: secOffer.id,
          matchedSupplyType: 'secondary',
        };
      }
    }

    // 3. TIER 3: Fallback (No staged demand match, but passes all hard rules)
    return {
      tier: 'TIER_3',
      matchReason: 'FALLBACK_NETWORK_EXPANSION',
      matchedInterestId: undefined,
      matchedInterestSlug: undefined,
      matchedInterestWeight: 0.05,
      matchedSupplyId: candidateB.primaryOfferId,
      matchedSupplyType: 'fallback',
    };
  }

  /**
   * Evaluates reverse direction (B -> A): Check if B also wants something A offers
   */
  static checkMutualDemand(
    userA: UserSupplyProfile,
    candidateB: UserSupplyProfile,
    demandB: UserStagedDemandProfile | undefined
  ): boolean {
    if (!demandB) return false;

    // Check if A's primary offer matches B's demand
    const primaryMatch = this.findDemandMatch(
      {
        id: userA.primaryOfferId,
        name: userA.primaryOfferName,
        slug: userA.primaryOfferSlug,
      },
      demandB
    );
    if (primaryMatch) return true;

    // Check if A's secondary offers match B's demand
    for (const secOffer of userA.secondaryOffers) {
      const secMatch = this.findDemandMatch(secOffer, demandB);
      if (secMatch) return true;
    }

    return false;
  }
}
