import { pool } from '../../db/pool';
import { UserSupplyProfile } from '../../types/matching_engine.types';

export class CandidateGeneratorService {
  /**
   * Loads existing active contact pairs and recent match pairs to avoid duplicate connections
   */
  static async loadExistingContactSet(): Promise<Set<string>> {
    const contactSet = new Set<string>();

    // 1. Existing contacts in user_contacts table
    const contactQuery = `SELECT owner_id, contact_user_id FROM user_contacts WHERE contact_user_id IS NOT NULL`;
    const { rows: contactRows } = await pool.query(contactQuery);
    for (const r of contactRows) {
      contactSet.add(`${r.owner_id}:${r.contact_user_id}`);
      contactSet.add(`${r.contact_user_id}:${r.owner_id}`);
    }

    // 2. Active contact_relationships table
    const relQuery = `SELECT user_a_id, user_b_id FROM contact_relationships WHERE status = 'ACTIVE'`;
    const { rows: relRows } = await pool.query(relQuery);
    for (const r of relRows) {
      contactSet.add(`${r.user_a_id}:${r.user_b_id}`);
      contactSet.add(`${r.user_b_id}:${r.user_a_id}`);
    }

    // 3. Historical matches from matches table
    const matchQuery = `SELECT user_a_id, user_b_id FROM matches`;
    const { rows: matchRows } = await pool.query(matchQuery);
    for (const r of matchRows) {
      contactSet.add(`${r.user_a_id}:${r.user_b_id}`);
      contactSet.add(`${r.user_b_id}:${r.user_a_id}`);
    }

    return contactSet;
  }

  /**
   * Strict Competitor Rule:
   * IF A.primary_offer == B.primary_offer THEN A and B cannot be automatically matched.
   * Only the primary-offer collision is a hard competitor exclusion.
   */
  static isCompetitor(userA: UserSupplyProfile, candidateB: UserSupplyProfile): boolean {
    if (!userA.primaryOfferId || !candidateB.primaryOfferId) return false;
    
    // Direct ID match on primary offer
    if (userA.primaryOfferId === candidateB.primaryOfferId) return true;

    // Normalized slug or name match on primary offer
    const slugA = (userA.primaryOfferSlug || userA.primaryOfferName).toLowerCase().trim();
    const slugB = (candidateB.primaryOfferSlug || candidateB.primaryOfferName).toLowerCase().trim();
    return slugA.length > 0 && slugA === slugB;
  }

  /**
   * Generates all eligible candidates for User A after hard exclusions
   */
  static generateEligibleCandidates(
    userA: UserSupplyProfile,
    allUsers: UserSupplyProfile[],
    existingContacts: Set<string>
  ): { candidates: UserSupplyProfile[]; competitorBlockedCount: number } {
    const candidates: UserSupplyProfile[] = [];
    let competitorBlockedCount = 0;

    for (const candidateB of allUsers) {
      // 1. Self-exclusion
      if (candidateB.userId === userA.userId) continue;

      // 2. Already active contact or previous match exclusion
      if (existingContacts.has(`${userA.userId}:${candidateB.userId}`)) continue;

      // 3. Hard Competitor Rule: Same primary offer = DENY
      if (this.isCompetitor(userA, candidateB)) {
        competitorBlockedCount++;
        continue;
      }

      // Candidate is eligible for tier classification and scoring
      candidates.push(candidateB);
    }

    return { candidates, competitorBlockedCount };
  }
}
