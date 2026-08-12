import { pool } from '../db/pool';
import { WallContentSelectionService } from './wall_content_selection.service';
import { WallSessionPayload } from '../types/interest_engine.types';

export class WallSessionService {
  /**
   * Starts or resumes a reproducible daily wall session for a user
   */
  static async getOrCreateDailySession(params: {
    userId: string;
    targetCount?: number;
  }): Promise<WallSessionPayload> {
    const { userId, targetCount = 5 } = params;

    // 1. Check if user already started an uncompleted session today
    const existingQuery = `
      SELECT session_id, date, item_count, target_mix, status
      FROM wall_sessions
      WHERE user_id = $1 AND date = CURRENT_DATE AND status = 'STARTED'
      ORDER BY started_at DESC
      LIMIT 1
    `;
    const { rows: existingRows } = await pool.query(existingQuery, [userId]);

    if (existingRows.length > 0) {
      const existingSession = existingRows[0];

      // Retrieve items for existing session
      const itemsQuery = `
        SELECT 
          wsi.content_id, wsi.order_index, wsi.pool_type,
          ci.format, ci.title_prompt, ci.description, ci.media_url,
          ci.media_type, ci.context_type
        FROM wall_session_items wsi
        JOIN content_items ci ON ci.id = wsi.content_id
        WHERE wsi.session_id = $1
        ORDER BY wsi.order_index ASC
      `;
      const { rows: sessionItemRows } = await pool.query(itemsQuery, [existingSession.session_id]);

      if (sessionItemRows.length > 0) {
        const contentIds = sessionItemRows.map(r => r.content_id);
        const optionsQuery = `
          SELECT content_id, option_key, label, subtext, media_url, order_index
          FROM content_options
          WHERE content_id = ANY($1)
          ORDER BY order_index ASC
        `;
        const { rows: optionRows } = await pool.query(optionsQuery, [contentIds]);

        return {
          session_id: existingSession.session_id,
          date: existingSession.date,
          item_count: sessionItemRows.length,
          target_mix: existingSession.target_mix,
          items: sessionItemRows.map(item => ({
            content_id: item.content_id,
            format: item.format,
            title_prompt: item.title_prompt,
            description: item.description,
            media_url: item.media_url,
            media_type: item.media_type,
            context_type: item.context_type,
            pool_type: item.pool_type,
            order_index: item.order_index,
            options: optionRows
              .filter(o => o.content_id === item.content_id)
              .map(o => ({
                option_key: o.option_key,
                label: o.label,
                subtext: o.subtext,
                media_url: o.media_url,
              })),
          })),
        };
      }
    }

    // 2. Select fresh content candidates
    const { items, targetMix } = await WallContentSelectionService.selectSessionContent({
      userId,
      targetCount,
    });

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Create new session
      const createSessionQuery = `
        INSERT INTO wall_sessions (user_id, date, item_count, target_mix, status)
        VALUES ($1, CURRENT_DATE, $2, $3, 'STARTED')
        RETURNING session_id, date, started_at
      `;
      const { rows: newSessionRows } = await client.query(createSessionQuery, [
        userId,
        items.length,
        JSON.stringify(targetMix),
      ]);
      const newSessionId = newSessionRows[0].session_id;

      // Insert session items
      for (const item of items) {
        await client.query(
          `INSERT INTO wall_session_items (session_id, content_id, order_index, pool_type)
           VALUES ($1, $2, $3, $4)`,
          [newSessionId, item.content_id, item.order_index, item.pool_type]
        );
      }

      await client.query('COMMIT');

      return {
        session_id: newSessionId,
        date: newSessionRows[0].date,
        item_count: items.length,
        items,
        target_mix: targetMix as any,
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Completes a wall session
   */
  static async completeSession(sessionId: string, userId: string): Promise<void> {
    const query = `
      UPDATE wall_sessions
      SET status = 'COMPLETED', completed_at = NOW()
      WHERE session_id = $1 AND user_id = $2
    `;
    await pool.query(query, [sessionId, userId]);
  }
}
