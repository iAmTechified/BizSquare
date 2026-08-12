export type MatchTier = 'TIER_1' | 'TIER_2' | 'TIER_3';

export type MatchReason =
  | 'PRIMARY_SUPPLY_MATCH'
  | 'SECONDARY_SUPPLY_MATCH'
  | 'FALLBACK_COMPLEMENTARY'
  | 'FALLBACK_ADJACENT'
  | 'FALLBACK_DIVERSE'
  | 'FALLBACK_NETWORK_EXPANSION';

export type AllocationStatus =
  | 'FILLED'
  | 'PARTIALLY_FILLED'
  | 'UNDERFILLED'
  | 'NO_ELIGIBLE_SUPPLY';

export type UnderfillReason =
  | 'INSUFFICIENT_ELIGIBLE_SUPPLY'
  | 'COMPETITOR_COLLISION_RESTRICTION'
  | 'ALL_CANDIDATES_CONNECTED';

export type MatchingCycleStatus = 'INITIATED' | 'RUNNING' | 'COMPLETED' | 'FAILED';

export interface UserSupplyProfile {
  userId: string;
  businessName: string;
  fullName?: string | undefined;
  phoneNumber?: string | undefined;
  avatarId: number;
  primaryOfferId: string;
  primaryOfferName: string;
  primaryOfferSlug: string;
  secondaryOffers: {
    id: string;
    name: string;
    slug: string;
  }[];
  secondaryOfferIds: string[];
}

export interface StagedDemandItem {
  taxonomyId: string;
  slug: string;
  name: string;
  weightPercentage: number; // e.g. 0.28 (28%)
  confidence: number;
  recencyScore: number;
  isBaseline: boolean;
}

export interface UserStagedDemandProfile {
  userId: string;
  items: StagedDemandItem[];
  demandMap: Map<string, StagedDemandItem>; // Keyed by taxonomyId / slug
}

export interface MatchCandidate {
  candidateId: string;
  tier: MatchTier;
  matchReason: MatchReason;
  matchedInterestId?: string | undefined;
  matchedInterestSlug?: string | undefined;
  matchedInterestWeight: number;
  matchedSupplyId?: string | undefined;
  matchedSupplyType: 'primary' | 'secondary' | 'fallback';
  isMutual: boolean;
  score: number;
  candidateSupply: UserSupplyProfile;
  explanationText: string;
}

export interface CandidateClassificationResult {
  tier: MatchTier;
  matchReason: MatchReason;
  matchedInterestId?: string | undefined;
  matchedInterestSlug?: string | undefined;
  matchedInterestWeight: number;
  matchedSupplyId?: string | undefined;
  matchedSupplyType: 'primary' | 'secondary' | 'fallback';
}

export interface UserAllocationPlan {
  userId: string;
  targetCount: number;
  allocatedCount: number;
  tier1Allocated: number;
  tier2Allocated: number;
  tier3Allocated: number;
  status: AllocationStatus;
  underfillReason?: UnderfillReason | undefined;
  allocations: {
    candidateId: string;
    tier: MatchTier;
    score: number;
    position: number;
    matchReason: MatchReason;
    matchedInterestId?: string | undefined;
    matchedInterestSlug?: string | undefined;
    matchedInterestWeight?: number | undefined;
    matchedSupplyId?: string | undefined;
    matchedSupplyType: 'primary' | 'secondary' | 'fallback';
    isMutual: boolean;
    explanationText: string;
  }[];
}

export interface WeeklyMatchingCycleResult {
  cycleId: string;
  cycleNumber: number;
  batchDate: string;
  networkSize: number;
  targetPerUser: number;
  usersProcessed: number;
  usersFilled: number;
  usersUnderfilled: number;
  totalAllocations: number;
  tier1Count: number;
  tier2Count: number;
  tier3Count: number;
  competitorExclusionsCount: number;
  executionDurationMs: number;
  status: MatchingCycleStatus;
}
