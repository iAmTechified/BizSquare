import { pool } from '../db/pool';
import { InterestStateService } from './interest_state.service';
import { RetentionAnalyticsService } from './retention_analytics.service';

export interface DemandConcentrationProfile {
  userId: string;
  primaryInterests: Array<{ taxonomyId: string; name: string; confidence: number }>;
  secondaryInterests: Array<{ taxonomyId: string; name: string; confidence: number }>;
  emergingInterests: Array<{ taxonomyId: string; name: string; confidence: number }>;
  backgroundInterests: Array<{ taxonomyId: string; name: string; confidence: number }>;
  updatedAt: string;
}

export class DemandConcentrationService {
  /**
   * Records an interaction in memory (Section 7) and updates the interest state graph.
   */
  static async recordInteraction(params: {
    userId: string;
    cardId: string;
    interactionType: string; // swipe | tap | choose | react | rank | slider | quick_response
    responseValue: Record<string, any>;
    taxonomyId?: string;
    skipped?: boolean;
  }): Promise<{
    success: boolean;
    feedbackMessage: string;
    confidenceUpdated: number;
  }> {
    const { userId, cardId, interactionType, responseValue, taxonomyId, skipped = false } = params;

    // 1. Calculate confidence score based on interaction type & recency
    let confidenceScore = skipped ? 0.20 : 0.70;
    if (interactionType === 'this_or_that' || interactionType === 'choose') {
      confidenceScore = 0.85;
    } else if (interactionType === 'slider') {
      const val = Number(responseValue.value ?? 0.5);
      confidenceScore = val > 0.5 ? 0.75 + (val - 0.5) * 0.4 : 0.40;
    } else if (interactionType === 'quick_response') {
      confidenceScore = 0.90;
    }

    // 2. Save/Upsert Interaction Memory
    await pool.query(
      `INSERT INTO user_wall_memory (
         user_id, card_id, interaction_type, response_value, confidence_score, skipped
       ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id, card_id) DO UPDATE SET
         interaction_type = EXCLUDED.interaction_type,
         response_value = EXCLUDED.response_value,
         confidence_score = EXCLUDED.confidence_score,
         skipped = EXCLUDED.skipped,
         created_at = CURRENT_TIMESTAMP`,
      [userId, cardId, interactionType, responseValue, confidenceScore, skipped]
    );

    // 3. Update Interest State Graph if taxonomyId is associated
    if (taxonomyId) {
      const signalType = skipped
        ? 'negative'
        : confidenceScore > 0.75
        ? 'intent'
        : 'positive';

      await InterestStateService.applySignalToUserInterest(
        userId,
        taxonomyId,
        signalType as any,
        confidenceScore
      );
    }

    // 4. Log retention analytics
    await RetentionAnalyticsService.trackEvent(
      userId,
      skipped ? 'daily_wall_skipped' : 'daily_wall_interaction',
      { cardId, interactionType, confidenceScore }
    );

    // 5. Generate lightweight, non-spam contextual feedback
    let feedbackMessage = skipped ? 'Skipped' : 'Got it';
    if (!skipped) {
      if (confidenceScore > 0.80) {
        feedbackMessage = 'Your network profile is getting sharper.';
      } else {
        feedbackMessage = 'Noted';
      }
    }

    // 6. Asynchronously update concentration profile
    setImmediate(() => {
      DemandConcentrationService.recalculateConcentrationProfile(userId).catch(() => {});
    });

    return {
      success: true,
      feedbackMessage,
      confidenceUpdated: confidenceScore,
    };
  }

  /**
   * Calculates the user's demand concentration profile into 4 tiers (Section 9):
   * Primary, Secondary, Emerging, Background.
   */
  static async recalculateConcentrationProfile(userId: string): Promise<DemandConcentrationProfile> {
    const { rows } = await pool.query(
      `SELECT 
         uis.taxonomy_id,
         COALESCE(mn.name, 'General Business') as taxonomy_name,
         uis.strength,
         uis.confidence,
         uis.state,
         uis.recency_score
       FROM user_interest_states uis
       LEFT JOIN micro_niches mn ON mn.id::text = uis.taxonomy_id
       WHERE uis.user_id = $1 AND uis.state != 'SUPPRESSED'
       ORDER BY (uis.strength * uis.confidence * uis.recency_score) DESC`,
      [userId]
    );

    const primary: Array<any> = [];
    const secondary: Array<any> = [];
    const emerging: Array<any> = [];
    const background: Array<any> = [];

    for (const r of rows) {
      const item = {
        taxonomyId: r.taxonomy_id,
        name: r.taxonomy_name,
        confidence: parseFloat(r.confidence) || 0.5,
      };

      const score = (parseFloat(r.strength) || 0) * (parseFloat(r.confidence) || 0);

      if (r.state === 'ONGOING' || score >= 0.65) {
        primary.push(item);
      } else if (r.state === 'ACTIVE' || score >= 0.35) {
        secondary.push(item);
      } else if (r.state === 'EMERGING') {
        emerging.push(item);
      } else {
        background.push(item);
      }
    }

    const now = new Date().toISOString();

    await pool.query(
      `INSERT INTO user_demand_profiles (
         user_id, primary_interests, secondary_interests, emerging_interests, background_interests, updated_at
       ) VALUES ($1, $2, $3, $4, $5, NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         primary_interests = EXCLUDED.primary_interests,
         secondary_interests = EXCLUDED.secondary_interests,
         emerging_interests = EXCLUDED.emerging_interests,
         background_interests = EXCLUDED.background_interests,
         updated_at = NOW()`,
      [
        userId,
        JSON.stringify(primary.slice(0, 5)),
        JSON.stringify(secondary.slice(0, 5)),
        JSON.stringify(emerging.slice(0, 5)),
        JSON.stringify(background.slice(0, 5)),
      ]
    );

    return {
      userId,
      primaryInterests: primary.slice(0, 5),
      secondaryInterests: secondary.slice(0, 5),
      emergingInterests: emerging.slice(0, 5),
      backgroundInterests: background.slice(0, 5),
      updatedAt: now,
    };
  }

  /**
   * Fetches user's current concentration profile for UI or matching engine consumption.
   */
  static async getConcentrationProfile(userId: string): Promise<DemandConcentrationProfile> {
    const { rows } = await pool.query(
      `SELECT * FROM user_demand_profiles WHERE user_id = $1`,
      [userId]
    );

    if (rows.length === 0) {
      return DemandConcentrationService.recalculateConcentrationProfile(userId);
    }

    const row = rows[0];
    return {
      userId,
      primaryInterests: row.primary_interests || [],
      secondaryInterests: row.secondary_interests || [],
      emergingInterests: row.emerging_interests || [],
      backgroundInterests: row.background_interests || [],
      updatedAt: row.updated_at.toISOString(),
    };
  }
}
