import { MATCHING_CONFIG } from '../config/matching.config';
import { CandidateGeneratorService } from '../services/matching/candidate_generator.service';
import { TierClassifierService } from '../services/matching/tier_classifier.service';
import { MatchScoringService } from '../services/matching/match_scoring.service';
import { NetworkAllocatorService } from '../services/matching/network_allocator.service';
import { UserSupplyProfile, UserStagedDemandProfile } from '../types/matching_engine.types';

function assert(condition: boolean, message: string) {
  if (!condition) {
    console.error(`❌ Assertion Failed: ${message}`);
    throw new Error(message);
  } else {
    console.log(`  ✓ ${message}`);
  }
}

async function runMatchingEngineTests() {
  console.log('\n======================================================');
  console.log('🧪 RUNNING BIZSQUARE MATCHING ENGINE TEST SUITE');
  console.log('======================================================\n');

  // Sample Profiles
  const userA_Shoes: UserSupplyProfile = {
    userId: 'user_a',
    businessName: 'Apex Footwear',
    avatarId: 1,
    primaryOfferId: 'niche_shoes',
    primaryOfferName: 'Footwear & Shoes',
    primaryOfferSlug: 'shoes',
    secondaryOffers: [
      { id: 'niche_bags', name: 'Leather Bags', slug: 'bags' },
    ],
    secondaryOfferIds: ['niche_bags'],
  };

  const userB_Watches: UserSupplyProfile = {
    userId: 'user_b',
    businessName: 'Grand Horology',
    avatarId: 2,
    primaryOfferId: 'niche_watches',
    primaryOfferName: 'Luxury Watches',
    primaryOfferSlug: 'watches',
    secondaryOffers: [
      { id: 'niche_shoes', name: 'Formal Shoes', slug: 'shoes' },
    ],
    secondaryOfferIds: ['niche_shoes'],
  };

  const userC_Shoes_Competitor: UserSupplyProfile = {
    userId: 'user_c',
    businessName: 'Sole King Footwear',
    avatarId: 3,
    primaryOfferId: 'niche_shoes',
    primaryOfferName: 'Footwear & Shoes',
    primaryOfferSlug: 'shoes',
    secondaryOffers: [],
    secondaryOfferIds: [],
  };

  const userD_Gadgets: UserSupplyProfile = {
    userId: 'user_d',
    businessName: 'Tech Haven',
    avatarId: 4,
    primaryOfferId: 'niche_gadgets',
    primaryOfferName: 'Consumer Gadgets',
    primaryOfferSlug: 'gadgets',
    secondaryOffers: [],
    secondaryOfferIds: [],
  };

  // Sample Staged Demand for User A
  const demandA: UserStagedDemandProfile = {
    userId: 'user_a',
    items: [
      {
        taxonomyId: 'niche_gadgets',
        slug: 'gadgets',
        name: 'Consumer Gadgets',
        weightPercentage: 0.50,
        confidence: 0.9,
        recencyScore: 1.0,
        isBaseline: false,
      },
      {
        taxonomyId: 'niche_watches',
        slug: 'watches',
        name: 'Luxury Watches',
        weightPercentage: 0.30,
        confidence: 0.8,
        recencyScore: 0.9,
        isBaseline: true,
      },
    ],
    demandMap: new Map([
      ['niche_gadgets', { taxonomyId: 'niche_gadgets', slug: 'gadgets', name: 'Consumer Gadgets', weightPercentage: 0.50, confidence: 0.9, recencyScore: 1.0, isBaseline: false }],
      ['gadgets', { taxonomyId: 'niche_gadgets', slug: 'gadgets', name: 'Consumer Gadgets', weightPercentage: 0.50, confidence: 0.9, recencyScore: 1.0, isBaseline: false }],
      ['niche_watches', { taxonomyId: 'niche_watches', slug: 'watches', name: 'Luxury Watches', weightPercentage: 0.30, confidence: 0.8, recencyScore: 0.9, isBaseline: true }],
      ['watches', { taxonomyId: 'niche_watches', slug: 'watches', name: 'Luxury Watches', weightPercentage: 0.30, confidence: 0.8, recencyScore: 0.9, isBaseline: true }],
    ]),
  };

  // Demand for User D (wants Shoes)
  const demandD: UserStagedDemandProfile = {
    userId: 'user_d',
    items: [
      {
        taxonomyId: 'niche_shoes',
        slug: 'shoes',
        name: 'Footwear & Shoes',
        weightPercentage: 0.60,
        confidence: 0.9,
        recencyScore: 1.0,
        isBaseline: true,
      }
    ],
    demandMap: new Map([
      ['niche_shoes', { taxonomyId: 'niche_shoes', slug: 'shoes', name: 'Footwear & Shoes', weightPercentage: 0.60, confidence: 0.9, recencyScore: 1.0, isBaseline: true }],
      ['shoes', { taxonomyId: 'niche_shoes', slug: 'shoes', name: 'Footwear & Shoes', weightPercentage: 0.60, confidence: 0.9, recencyScore: 1.0, isBaseline: true }],
    ]),
  };

  console.log('--- 1. Hard Competitor Rule Tests ---');
  // Test 1.1: Same primary offer = Competitor (DENY)
  const isCompetitor_AC = CandidateGeneratorService.isCompetitor(userA_Shoes, userC_Shoes_Competitor);
  assert(isCompetitor_AC === true, 'A.primary == C.primary (Shoes vs Shoes) -> Competitor Detected (DENY)');

  // Test 1.2: Different primary offers = NOT competitor even if secondary matches (ALLOW)
  const isCompetitor_AB = CandidateGeneratorService.isCompetitor(userA_Shoes, userB_Watches);
  assert(isCompetitor_AB === false, 'A.primary (Shoes) != B.primary (Watches) -> Not Competitor (ALLOW) even with B.secondary=Shoes');

  // Test 1.3: Candidate Generator filters competitor and self
  const { candidates: candList, competitorBlockedCount } = CandidateGeneratorService.generateEligibleCandidates(
    userA_Shoes,
    [userA_Shoes, userB_Watches, userC_Shoes_Competitor, userD_Gadgets],
    new Set()
  );
  assert(candList.length === 2, 'Candidate generator returns only eligible non-competitors (B and D)');
  assert(competitorBlockedCount === 1, 'Candidate generator recorded 1 competitor exclusion');
  assert(!candList.some(c => c.userId === 'user_c'), 'Competitor C is strictly excluded from candidate list');
  assert(!candList.some(c => c.userId === 'user_a'), 'Self-candidate A is strictly excluded');

  console.log('\n--- 2. Tier Classification Tests ---');
  // Test 2.1: Primary Supply Match -> TIER 1
  const classD = TierClassifierService.classifyCandidate(userA_Shoes, userD_Gadgets, demandA);
  assert(classD.tier === 'TIER_1', 'D.primary (Gadgets) matches A demand (Gadgets) -> TIER 1');
  assert(classD.matchReason === 'PRIMARY_SUPPLY_MATCH', 'Reason is PRIMARY_SUPPLY_MATCH');

  // Test 2.2: Secondary Supply Match -> TIER 2
  const demandA_BagsOnly: UserStagedDemandProfile = {
    userId: 'user_a',
    items: [{ taxonomyId: 'niche_shoes', slug: 'shoes', name: 'Shoes', weightPercentage: 0.4, confidence: 0.8, recencyScore: 1.0, isBaseline: true }],
    demandMap: new Map([['niche_shoes', { taxonomyId: 'niche_shoes', slug: 'shoes', name: 'Shoes', weightPercentage: 0.4, confidence: 0.8, recencyScore: 1.0, isBaseline: true }]]),
  };
  const classB_Sec = TierClassifierService.classifyCandidate(userD_Gadgets, userB_Watches, demandA_BagsOnly);
  assert(classB_Sec.tier === 'TIER_2', 'B.secondary (Shoes) matches demand -> TIER 2');
  assert(classB_Sec.matchReason === 'SECONDARY_SUPPLY_MATCH', 'Reason is SECONDARY_SUPPLY_MATCH');

  // Test 2.3: Non-interest Fallback -> TIER 3
  const demandEmpty: UserStagedDemandProfile = {
    userId: 'user_a',
    items: [],
    demandMap: new Map(),
  };
  const classFallback = TierClassifierService.classifyCandidate(userA_Shoes, userD_Gadgets, demandEmpty);
  assert(classFallback.tier === 'TIER_3', 'No demand match -> TIER 3 Fallback');
  assert(classFallback.matchReason === 'FALLBACK_NETWORK_EXPANSION', 'Reason is FALLBACK_NETWORK_EXPANSION');

  // Test 2.4: Mutuality Check (B -> A)
  const isMutual_AD = TierClassifierService.checkMutualDemand(userA_Shoes, userD_Gadgets, demandD);
  assert(isMutual_AD === true, 'A offers Shoes and D wants Shoes -> Mutual Demand Detected (true)');

  const isMutual_AB = TierClassifierService.checkMutualDemand(userA_Shoes, userB_Watches, demandEmpty);
  assert(isMutual_AB === false, 'B has empty demand -> Mutual Demand is false');

  console.log('\n--- 3. Multi-Factor Scoring Tests ---');
  // Test 3.1: Tier 1 candidate outranks Tier 2 and Tier 3
  const score1 = MatchScoringService.scoreCandidate({
    userA: userA_Shoes,
    candidateB: userD_Gadgets,
    classification: classD,
    demandA,
    isMutual: true,
    candidateExposureCount: 0,
    userTopicExposureCount: 0,
    existingCategoriesInNetwork: new Set(),
  });

  const score3 = MatchScoringService.scoreCandidate({
    userA: userA_Shoes,
    candidateB: userD_Gadgets,
    classification: classFallback,
    demandA,
    isMutual: false,
    candidateExposureCount: 0,
    userTopicExposureCount: 0,
    existingCategoriesInNetwork: new Set(),
  });

  assert(score1.score > score3.score, `Tier 1 score (${score1.score}) > Tier 3 score (${score3.score})`);
  assert(score1.score >= 1000, `Tier 1 base weight >= 1000`);
  assert(score1.explanationText.includes('Consumer Gadgets'), 'Generated explanation mentions matched niche');

  console.log('\n--- 4. 10% Volume Rule & Underfill Tests ---');
  // Test 4.1: Target calculation floor
  assert(MATCHING_CONFIG.calculateWeeklyTarget(1000) === 100, 'Network size 1000 -> Target = 100');
  assert(MATCHING_CONFIG.calculateWeeklyTarget(50) === 5, 'Network size 50 -> Target = 5');
  assert(MATCHING_CONFIG.calculateWeeklyTarget(5) === 1, 'Network size 5 -> Target = 1 (Min Cap 1)');

  // Test 4.2: Underfill handling when eligible supply < 10%
  const stagedMap = new Map([
    ['user_a', demandA],
    ['user_b', demandEmpty],
    ['user_c', demandEmpty],
    ['user_d', demandD],
  ]);

  const { plans } = NetworkAllocatorService.planNetworkAllocations({
    allUsers: [userA_Shoes, userB_Watches, userC_Shoes_Competitor, userD_Gadgets],
    stagedDemands: stagedMap,
    existingContacts: new Set(),
  });

  assert(plans.length === 4, 'All 4 users received an allocation plan');
  const planA = plans.find(p => p.userId === 'user_a')!;
  assert(planA.allocatedCount <= planA.targetCount, 'Allocated count does not exceed target');
  assert(!planA.allocations.some(a => a.candidateId === 'user_c'), 'Competitor C is never allocated to A');

  console.log('\n======================================================');
  console.log('✅ ALL MATCHING ENGINE UNIT TESTS PASSED SUCCESSFULLY!');
  console.log('======================================================\n');
}

runMatchingEngineTests().catch(err => {
  console.error('Test Suite Failed:', err);
  process.exit(1);
});
