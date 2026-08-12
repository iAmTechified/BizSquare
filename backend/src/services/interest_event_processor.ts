import { pool } from '../db/pool';
import { InterestSignalService } from './interest_signal.service';
import { InterestStateService } from './interest_state.service';
import { ContentFormat } from '../types/interest_engine.types';

export class InterestEventProcessor {
  /**
   * Ingests a raw interaction event with strict idempotency (event_id key)
   */
  static async processInteractionEvent(params: {
    eventId?: string;
    userId: string;
    sessionId?: string;
    contentId: string;
    format: ContentFormat;
    optionId: string;
    interactionType: string;
    dwellMs?: number;
    metadata?: Record<string, any>;
  }): Promise<{ eventId: string; signalsCount: number }> {
    const {
      eventId,
      userId,
      sessionId,
      contentId,
      format,
      optionId,
      interactionType,
      dwellMs = 0,
      metadata = {},
    } = params;

    // 1. Insert raw immutable event with idempotency
    const insertEventQuery = `
      INSERT INTO interest_events (
        event_id, user_id, session_id, content_id, format,
        option_id, interaction_type, dwell_ms, metadata
      ) VALUES (
        COALESCE($1, uuid_generate_v4()), $2, $3, $4, $5, $6, $7, $8, $9
      )
      ON CONFLICT (event_id) DO NOTHING
      RETURNING event_id
    `;
    const { rows: eventRows } = await pool.query(insertEventQuery, [
      eventId || null,
      userId,
      sessionId || null,
      contentId,
      format,
      optionId,
      interactionType,
      dwellMs,
      JSON.stringify(metadata),
    ]);

    if (eventRows.length === 0) {
      // Event was already processed (idempotency key hit)
      return { eventId: eventId!, signalsCount: 0 };
    }

    const recordedEventId = eventRows[0].event_id;

    // 2. Log interaction in session if session_id provided
    if (sessionId) {
      const logSessionInteractionQuery = `
        INSERT INTO wall_interactions (
          session_id, content_id, option_id, interaction_type, dwell_ms
        ) VALUES ($1, $2, $3, $4, $5)
      `;
      await pool.query(logSessionInteractionQuery, [
        sessionId,
        contentId,
        optionId,
        interactionType,
        dwellMs,
      ]);
    }

    // 3. Update content performance metrics
    const perfQuery = `
      INSERT INTO content_performance (
        content_id, impressions_count, interactions_count, skips_count,
        completions_count, avg_dwell_ms, last_served_at
      ) VALUES (
        $1, 1, 
        CASE WHEN $2 IN ('select', 'tap', 'react', 'positive', 'swipe_right') THEN 1 ELSE 0 END,
        CASE WHEN $2 IN ('skip', 'swipe_left') THEN 1 ELSE 0 END,
        1, $3, NOW()
      )
      ON CONFLICT (content_id) DO UPDATE SET
        interactions_count = content_performance.interactions_count + (CASE WHEN $2 IN ('select', 'tap', 'react', 'positive', 'swipe_right') THEN 1 ELSE 0 END),
        skips_count = content_performance.skips_count + (CASE WHEN $2 IN ('skip', 'swipe_left') THEN 1 ELSE 0 END),
        completions_count = content_performance.completions_count + 1,
        avg_dwell_ms = (content_performance.avg_dwell_ms + $3) / 2,
        last_served_at = NOW()
    `;
    await pool.query(perfQuery, [contentId, interactionType, dwellMs]);

    // 4. Resolve structured signals from option
    const signals = await InterestSignalService.resolveSignalsForInteraction(contentId, optionId);

    // 5. Record signals
    if (signals.length > 0) {
      await InterestSignalService.recordSignals(recordedEventId, userId, signals);

      // 6. Asynchronously apply each signal to the user's interest state graph
      for (const signal of signals) {
        await InterestStateService.applySignalToUserInterest(
          userId,
          signal.taxonomy_id,
          signal.signal_type,
          signal.weight,
          signal.context
        );
      }
    }

    return { eventId: recordedEventId, signalsCount: signals.length };
  }
}
