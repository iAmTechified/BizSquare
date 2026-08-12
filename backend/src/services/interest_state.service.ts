import { pool } from '../db/pool';
import { InterestLifecycleState, SignalType } from '../types/interest_engine.types';

export class InterestStateService {
  /**
   * Applies new signals to update a user's interest state graph
   */
  static async applySignalToUserInterest(
    userId: string,
    taxonomyId: string,
    signalType: SignalType,
    weight: number,
    context: string = 'general'
  ): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Fetch existing state
      const existingQuery = `
        SELECT * FROM user_interest_states 
        WHERE user_id = $1 AND taxonomy_id = $2
        FOR UPDATE
      `;
      const { rows } = await client.query(existingQuery, [userId, taxonomyId]);

      const now = new Date();
      let state: InterestLifecycleState = 'EMERGING';
      let strength = 0.25;
      let confidence = 0.15;
      let frequencyCount = 1;
      let positiveCount = signalType === 'positive' || signalType === 'intent' || signalType === 'weak_positive' ? 1 : 0;
      let negativeCount = signalType === 'negative' ? 1 : 0;
      let lastPositiveAt = positiveCount > 0 ? now : null;
      let lastNegativeAt = negativeCount > 0 ? now : null;

      if (rows.length > 0) {
        const curr = rows[0];
        frequencyCount = curr.frequency_count + 1;
        positiveCount = curr.positive_signal_count + (signalType === 'positive' || signalType === 'intent' || signalType === 'weak_positive' ? 1 : 0);
        negativeCount = curr.negative_signal_count + (signalType === 'negative' ? 1 : 0);
        lastPositiveAt = positiveCount > curr.positive_signal_count ? now : curr.last_positive_at;
        lastNegativeAt = negativeCount > curr.negative_signal_count ? now : curr.last_negative_at;

        // Apply signal delta
        const delta = signalType === 'intent' ? 0.35 * weight :
                      signalType === 'positive' ? 0.20 * weight :
                      signalType === 'weak_positive' ? 0.10 * weight :
                      signalType === 'negative' ? -0.30 * Math.abs(weight) : 0.05;

        // Dynamic strength clamped between 0.0 and 1.0
        strength = Math.min(1.0, Math.max(0.0, Number(curr.strength) + delta));

        // Confidence increases with frequency & consistent positive interactions (asymptotic)
        confidence = Math.min(0.98, Number(curr.confidence) + (positiveCount > 0 ? 0.08 : -0.05));

        // Lifecycle state transition logic
        if (negativeCount >= 2 && lastNegativeAt && (now.getTime() - new Date(lastNegativeAt).getTime() < 3 * 86400000)) {
          state = 'SUPPRESSED';
        } else if (positiveCount >= 4 && strength >= 0.70) {
          state = 'ONGOING';
        } else if (positiveCount >= 2 && strength >= 0.40) {
          state = 'ACTIVE';
        } else if (strength < 0.20 && frequencyCount > 2) {
          state = 'DORMANT';
        } else {
          state = 'EMERGING';
        }

        const updateQuery = `
          UPDATE user_interest_states SET
            state = $1,
            strength = $2,
            confidence = $3,
            recency_score = 1.000,
            frequency_count = $4,
            positive_signal_count = $5,
            negative_signal_count = $6,
            last_positive_at = COALESCE($7, last_positive_at),
            last_negative_at = COALESCE($8, last_negative_at),
            last_observed_at = $9,
            updated_at = NOW()
          WHERE id = $10
        `;
        await client.query(updateQuery, [
          state,
          strength.toFixed(3),
          confidence.toFixed(3),
          frequencyCount,
          positiveCount,
          negativeCount,
          lastPositiveAt,
          lastNegativeAt,
          now,
          curr.id,
        ]);
      } else {
        // Initial entry
        if (signalType === 'negative') {
          state = 'SUPPRESSED';
          strength = 0.05;
        } else if (signalType === 'intent') {
          state = 'ACTIVE';
          strength = 0.60;
          confidence = 0.30;
        }

        const insertQuery = `
          INSERT INTO user_interest_states (
            user_id, taxonomy_id, state, strength, confidence, recency_score,
            frequency_count, positive_signal_count, negative_signal_count,
            last_positive_at, last_negative_at, first_observed_at, last_observed_at
          ) VALUES ($1, $2, $3, $4, $5, 1.000, $6, $7, $8, $9, $10, $11, $11)
        `;
        await client.query(insertQuery, [
          userId,
          taxonomyId,
          state,
          strength.toFixed(3),
          confidence.toFixed(3),
          frequencyCount,
          positiveCount,
          negativeCount,
          lastPositiveAt,
          lastNegativeAt,
          now,
        ]);
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Performs recency decay over time (e.g. 14-day half-life decay)
   */
  static async runRecencyDecay(): Promise<void> {
    const query = `
      UPDATE user_interest_states
      SET 
        recency_score = GREATEST(0.05, recency_score * EXP(-0.05 * EXTRACT(EPOCH FROM (NOW() - last_observed_at)) / 86400)),
        strength = GREATEST(0.05, strength * EXP(-0.03 * EXTRACT(EPOCH FROM (NOW() - last_observed_at)) / 86400)),
        state = CASE 
          WHEN state = 'ACTIVE' AND strength < 0.35 THEN 'DORMANT'
          WHEN state = 'SUPPRESSED' AND last_negative_at < NOW() - INTERVAL '14 days' THEN 'DORMANT'
          ELSE state 
        END,
        updated_at = NOW()
      WHERE last_observed_at < NOW() - INTERVAL '1 day';
    `;
    await pool.query(query);
  }
}
