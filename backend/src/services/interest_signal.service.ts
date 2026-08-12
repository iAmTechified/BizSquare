import { pool } from '../db/pool';
import { ContentSignalMapping, SignalType } from '../types/interest_engine.types';

export class InterestSignalService {
  /**
   * Resolves signal mappings for a content interaction
   */
  static async resolveSignalsForInteraction(
    contentId: string,
    optionKeyOrId: string
  ): Promise<ContentSignalMapping[]> {
    // Check if optionKeyOrId matches option_key or option id
    const query = `
      SELECT 
        csm.id, csm.content_id, csm.option_id, csm.taxonomy_id,
        csm.signal_type, csm.weight, csm.context,
        t.slug as taxonomy_slug, t.name as taxonomy_name
      FROM content_signal_mappings csm
      JOIN content_options co ON co.id = csm.option_id
      JOIN interest_taxonomies t ON t.id = csm.taxonomy_id
      WHERE csm.content_id = $1 
        AND (co.option_key = $2 OR co.id::text = $2)
    `;
    const { rows } = await pool.query(query, [contentId, optionKeyOrId]);

    // If no explicit signal mapping is stored, fallback to primary taxonomy
    if (rows.length === 0) {
      const fallbackQuery = `
        SELECT ctl.taxonomy_id, t.slug as taxonomy_slug, t.name as taxonomy_name
        FROM content_taxonomy_links ctl
        JOIN interest_taxonomies t ON t.id = ctl.taxonomy_id
        WHERE ctl.content_id = $1 AND ctl.is_primary = TRUE
      `;
      const { rows: fallbackRows } = await pool.query(fallbackQuery, [contentId]);
      if (fallbackRows.length > 0) {
        return [{
          content_id: contentId,
          taxonomy_id: fallbackRows[0].taxonomy_id,
          taxonomy_slug: fallbackRows[0].taxonomy_slug,
          taxonomy_name: fallbackRows[0].taxonomy_name,
          signal_type: 'positive',
          weight: 1.0,
          context: 'general',
        }];
      }
    }

    return rows;
  }

  /**
   * Records generated signals into interest_signals table
   */
  static async recordSignals(
    eventId: string,
    userId: string,
    signals: ContentSignalMapping[]
  ): Promise<void> {
    if (signals.length === 0) return;

    const values: any[] = [];
    const valuePlaceholders: string[] = [];

    signals.forEach((s, idx) => {
      const offset = idx * 6;
      valuePlaceholders.push(`($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5}, $${offset + 6})`);
      values.push(
        eventId,
        userId,
        s.taxonomy_id,
        s.signal_type || 'positive',
        s.weight || 1.0,
        s.context || 'general'
      );
    });

    const query = `
      INSERT INTO interest_signals (
        event_id, user_id, taxonomy_id, signal_type, weight, context
      ) VALUES ${valuePlaceholders.join(', ')}
    `;
    await pool.query(query, values);
  }
}
