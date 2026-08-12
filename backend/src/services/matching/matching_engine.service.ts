import { pool } from '../../db/pool';
import { MATCHING_CONFIG } from '../../config/matching.config';
import { WeeklyMatchingCycleResult } from '../../types/matching_engine.types';
import { SupplyProfileService } from './supply_profile.service';
import { StagedDemandService } from './staged_demand.service';
import { CandidateGeneratorService } from './candidate_generator.service';
import { NetworkAllocatorService } from './network_allocator.service';
import { ContactSyncService } from './contact_sync.service';

export class MatchingEngineService {
  /**
   * Runs the complete weekly matching cycle with transactional safety and full idempotency.
   */
  static async runWeeklyMatchingCycle(): Promise<WeeklyMatchingCycleResult> {
    const startTime = Date.now();
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // 1. Initialize cycle record
      const { rows: [cycle] } = await client.query(`
        INSERT INTO weekly_matching_cycles (
          batch_date, status, allocation_percentage
        ) VALUES (
          CURRENT_DATE, 'RUNNING', $1
        ) RETURNING id, cycle_number, batch_date
      `, [MATCHING_CONFIG.WEEKLY_ALLOCATION_PERCENTAGE]);

      const cycleId = cycle.id;
      const cycleNumber = cycle.cycle_number;
      const batchDate = cycle.batch_date.toISOString().split('T')[0];

      // 2. Load all eligible supply profiles
      const supplyProfilesMap = await SupplyProfileService.loadAllSupplyProfiles();
      const allUsers = Array.from(supplyProfilesMap.values());
      const networkSize = allUsers.length;
      const targetPerUser = MATCHING_CONFIG.calculateWeeklyTarget(networkSize);

      if (networkSize === 0) {
        await client.query(`
          UPDATE weekly_matching_cycles
          SET status = 'COMPLETED', completed_at = CURRENT_TIMESTAMP, network_size = 0
          WHERE id = $1
        `, [cycleId]);
        await client.query('COMMIT');

        return {
          cycleId,
          cycleNumber,
          batchDate,
          networkSize: 0,
          targetPerUser: 0,
          usersProcessed: 0,
          usersFilled: 0,
          usersUnderfilled: 0,
          totalAllocations: 0,
          tier1Count: 0,
          tier2Count: 0,
          tier3Count: 0,
          competitorExclusionsCount: 0,
          executionDurationMs: Date.now() - startTime,
          status: 'COMPLETED',
        };
      }

      // 3. Ingest Staged Demands & Contact Set
      const userIds = allUsers.map(u => u.userId);
      const stagedDemands = await StagedDemandService.loadAllStagedDemands(userIds);
      const existingContacts = await CandidateGeneratorService.loadExistingContactSet();

      // 4. Plan network allocations (with 10% volume ceiling, tier priority, exposure balancing)
      const { plans, totalCompetitorExclusions } = NetworkAllocatorService.planNetworkAllocations({
        allUsers,
        stagedDemands,
        existingContacts,
      });

      let totalAllocations = 0;
      let tier1Count = 0;
      let tier2Count = 0;
      let tier3Count = 0;
      let usersFilled = 0;
      let usersUnderfilled = 0;

      // 5. Persist allocations, audit history, and reciprocal contacts
      for (const plan of plans) {
        if (plan.status === 'FILLED') {
          usersFilled++;
        } else {
          usersUnderfilled++;
        }

        tier1Count += plan.tier1Allocated;
        tier2Count += plan.tier2Allocated;
        tier3Count += plan.tier3Allocated;
        totalAllocations += plan.allocatedCount;

        // Persist cycle user summary
        await client.query(`
          INSERT INTO cycle_allocation_summaries (
            cycle_id, user_id, target_count, allocated_count,
            tier_1_allocated, tier_2_allocated, tier_3_allocated,
            allocation_status, underfill_reason
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9
          )
        `, [
          cycleId,
          plan.userId,
          plan.targetCount,
          plan.allocatedCount,
          plan.tier1Allocated,
          plan.tier2Allocated,
          plan.tier3Allocated,
          plan.status,
          plan.underfillReason || null,
        ]);

        const userAProfile = supplyProfilesMap.get(plan.userId)!;

        // Persist individual candidate allocations
        for (const alloc of plan.allocations) {
          const candidateBProfile = supplyProfilesMap.get(alloc.candidateId)!;

          // Insert match allocation
          const { rows: [allocRow] } = await client.query(`
            INSERT INTO match_allocations (
              cycle_id, user_id, candidate_user_id, tier, final_score,
              allocation_position, match_reason, matched_interest_id,
              matched_interest_slug, matched_interest_weight,
              matched_supply_id, matched_supply_type, is_mutual, status
            ) VALUES (
              $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'ALLOCATED'
            ) RETURNING id
          `, [
            cycleId,
            plan.userId,
            alloc.candidateId,
            alloc.tier,
            alloc.score,
            alloc.position,
            alloc.matchReason,
            alloc.matchedInterestId || null,
            alloc.matchedInterestSlug || null,
            alloc.matchedInterestWeight || null,
            alloc.matchedSupplyId || null,
            alloc.matchedSupplyType,
            alloc.isMutual,
          ]);

          const matchId = allocRow.id;

          // Insert match history (Audit Log)
          await client.query(`
            INSERT INTO match_history (
              cycle_id, user_a, user_b, tier, score, match_reason,
              interest_used, interest_weight, supply_used, supply_type,
              candidate_primary_offer, candidate_secondary_offers,
              mutual_match, allocation_position, explanation_text
            ) VALUES (
              $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
            )
          `, [
            cycleId,
            plan.userId,
            alloc.candidateId,
            alloc.tier,
            alloc.score,
            alloc.matchReason,
            alloc.matchedInterestSlug || null,
            alloc.matchedInterestWeight || null,
            candidateBProfile.primaryOfferName,
            alloc.matchedSupplyType,
            candidateBProfile.primaryOfferName,
            candidateBProfile.secondaryOffers.map(s => s.name),
            alloc.isMutual,
            alloc.position,
            alloc.explanationText,
          ]);

          // Reciprocal contact creation (A -> B and B -> A)
          await ContactSyncService.createReciprocalContacts(
            client,
            cycleId,
            matchId,
            userAProfile,
            candidateBProfile
          );
        }
      }

      const executionDurationMs = Date.now() - startTime;

      // 6. Update cycle record with completed metrics
      await client.query(`
        UPDATE weekly_matching_cycles
        SET 
          status = 'COMPLETED',
          network_size = $1,
          target_per_user = $2,
          users_processed = $3,
          users_filled = $4,
          users_underfilled = $5,
          total_allocations = $6,
          tier_1_count = $7,
          tier_2_count = $8,
          tier_3_count = $9,
          competitor_exclusions_count = $10,
          execution_duration_ms = $11,
          completed_at = CURRENT_TIMESTAMP
        WHERE id = $12
      `, [
        networkSize,
        targetPerUser,
        plans.length,
        usersFilled,
        usersUnderfilled,
        totalAllocations,
        tier1Count,
        tier2Count,
        tier3Count,
        totalCompetitorExclusions,
        executionDurationMs,
        cycleId,
      ]);

      await client.query('COMMIT');

      return {
        cycleId,
        cycleNumber,
        batchDate,
        networkSize,
        targetPerUser,
        usersProcessed: plans.length,
        usersFilled,
        usersUnderfilled,
        totalAllocations,
        tier1Count,
        tier2Count,
        tier3Count,
        competitorExclusionsCount: totalCompetitorExclusions,
        executionDurationMs,
        status: 'COMPLETED',
      };
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Matching cycle failed:', error);
      throw error;
    } finally {
      client.release();
    }
  }
}
