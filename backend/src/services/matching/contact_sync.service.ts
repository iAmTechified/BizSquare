import { PoolClient } from 'pg';
import { UserSupplyProfile } from '../../types/matching_engine.types';

export class ContactSyncService {
  /**
   * Persists reciprocal contacts in user_contacts and contact_relationships
   */
  static async createReciprocalContacts(
    client: PoolClient,
    cycleId: string,
    matchId: string,
    userA: UserSupplyProfile,
    candidateB: UserSupplyProfile
  ): Promise<void> {
    // 1. Insert contact for User A (Owner A -> Contact B)
    const queryA = `
      INSERT INTO user_contacts (
        owner_id, contact_user_id, external_name, external_phone, label, lead_grade, notes
      ) VALUES (
        $1, $2, $3, $4, 'lead', 'B', $5
      )
      ON CONFLICT (owner_id, contact_user_id) DO NOTHING
    `;
    await client.query(queryA, [
      userA.userId,
      candidateB.userId,
      candidateB.businessName || candidateB.fullName || 'BizSquare Contact',
      candidateB.phoneNumber || '',
      `Matched via BizSquare Weekly Cycle (Primary: ${candidateB.primaryOfferName})`
    ]);

    // 2. Insert contact for Candidate B (Owner B -> Contact A) - RECIPROCAL
    const queryB = `
      INSERT INTO user_contacts (
        owner_id, contact_user_id, external_name, external_phone, label, lead_grade, notes
      ) VALUES (
        $1, $2, $3, $4, 'lead', 'B', $5
      )
      ON CONFLICT (owner_id, contact_user_id) DO NOTHING
    `;
    await client.query(queryB, [
      candidateB.userId,
      userA.userId,
      userA.businessName || userA.fullName || 'BizSquare Contact',
      userA.phoneNumber || '',
      `Matched via BizSquare Weekly Cycle (Primary: ${userA.primaryOfferName})`
    ]);

    // 3. Insert canonical reciprocal relationship into contact_relationships
    const u1 = userA.userId < candidateB.userId ? userA.userId : candidateB.userId;
    const u2 = userA.userId < candidateB.userId ? candidateB.userId : userA.userId;

    const relQuery = `
      INSERT INTO contact_relationships (
        user_a_id, user_b_id, source, match_id, cycle_id, status, sync_status
      ) VALUES (
        $1, $2, 'AUTOMATIC_MATCH', $3, $4, 'ACTIVE', 'PENDING_SYNC'
      )
      ON CONFLICT (user_a_id, user_b_id) DO NOTHING
    `;
    await client.query(relQuery, [u1, u2, matchId, cycleId]);
  }

  /**
   * Marks a contact relationship as successfully synced with WhatsApp / Mobile device
   */
  static async markSyncCompleted(client: PoolClient, relationshipId: string): Promise<void> {
    await client.query(
      `UPDATE contact_relationships 
       SET sync_status = 'SYNCED', last_synced_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [relationshipId]
    );
  }
}
