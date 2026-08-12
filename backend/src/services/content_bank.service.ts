import { pool } from '../db/pool';
import { ContentItem, ContentStatus, ContentFormat } from '../types/interest_engine.types';
import { InterestTaxonomyService } from './interest_taxonomy.service';

export class ContentBankService {
  /**
   * Retrieves content items with filtering and pagination
   */
  static async getContentItems(params: {
    taxonomyId?: string;
    format?: ContentFormat;
    status?: ContentStatus;
    contextType?: string;
    search?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ items: ContentItem[]; total: number }> {
    const { taxonomyId, format, status, contextType, search, limit = 50, offset = 0 } = params;

    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (status) {
      conditions.push(`ci.status = $${idx++}`);
      values.push(status);
    }
    if (format) {
      conditions.push(`ci.format = $${idx++}`);
      values.push(format);
    }
    if (contextType) {
      conditions.push(`ci.context_type = $${idx++}`);
      values.push(contextType);
    }
    if (search) {
      conditions.push(`(ci.title_prompt ILIKE $${idx} OR ci.description ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }
    if (taxonomyId) {
      conditions.push(`EXISTS(SELECT 1 FROM content_taxonomy_links ctl WHERE ctl.content_id = ci.id AND ctl.taxonomy_id = $${idx++})`);
      values.push(taxonomyId);
    }

    const whereStr = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countQuery = `SELECT COUNT(*) FROM content_items ci ${whereStr}`;
    const { rows: countRows } = await pool.query(countQuery, values);
    const total = parseInt(countRows[0].count, 10);

    const query = `
      SELECT 
        ci.*,
        cp.impressions_count, cp.interactions_count, cp.skips_count,
        cp.completions_count, cp.avg_dwell_ms, cp.positive_signals_generated
      FROM content_items ci
      LEFT JOIN content_performance cp ON cp.content_id = ci.id
      ${whereStr}
      ORDER BY ci.created_at DESC
      LIMIT $${idx++} OFFSET $${idx++}
    `;
    const { rows: itemRows } = await pool.query(query, [...values, limit, offset]);

    if (itemRows.length === 0) {
      return { items: [], total };
    }

    const contentIds = itemRows.map(r => r.id);

    // Fetch options
    const optionsQuery = `
      SELECT co.*, csm.taxonomy_id, csm.signal_type, csm.weight, csm.context as signal_context,
             t.name as taxonomy_name, t.slug as taxonomy_slug
      FROM content_options co
      LEFT JOIN content_signal_mappings csm ON csm.option_id = co.id
      LEFT JOIN interest_taxonomies t ON t.id = csm.taxonomy_id
      WHERE co.content_id = ANY($1)
      ORDER BY co.order_index ASC
    `;
    const { rows: optionRows } = await pool.query(optionsQuery, [contentIds]);

    // Fetch taxonomy links
    const taxLinksQuery = `
      SELECT ctl.content_id, ctl.is_primary, t.id, t.name, t.slug
      FROM content_taxonomy_links ctl
      JOIN interest_taxonomies t ON t.id = ctl.taxonomy_id
      WHERE ctl.content_id = ANY($1)
    `;
    const { rows: taxRows } = await pool.query(taxLinksQuery, [contentIds]);

    const items: ContentItem[] = itemRows.map(row => {
      const options = optionRows
        .filter(o => o.content_id === row.id)
        .map(o => ({
          id: o.id,
          content_id: o.content_id,
          option_key: o.option_key,
          label: o.label,
          subtext: o.subtext,
          media_url: o.media_url,
          order_index: o.order_index,
          signals: o.taxonomy_id ? [{
            content_id: o.content_id,
            option_id: o.id,
            taxonomy_id: o.taxonomy_id,
            taxonomy_slug: o.taxonomy_slug,
            taxonomy_name: o.taxonomy_name,
            signal_type: o.signal_type,
            weight: Number(o.weight),
            context: o.signal_context,
          }] : [],
        }));

      const taxonomies = taxRows
        .filter(t => t.content_id === row.id)
        .map(t => ({
          id: t.id,
          name: t.name,
          slug: t.slug,
          is_primary: t.is_primary,
        }));

      return {
        id: row.id,
        format: row.format,
        status: row.status,
        title_prompt: row.title_prompt,
        description: row.description,
        media_url: row.media_url,
        media_type: row.media_type,
        context_type: row.context_type,
        target_audience: row.target_audience,
        difficulty: row.difficulty,
        version: row.version,
        batch_id: row.batch_id,
        created_by: row.created_by,
        created_at: row.created_at,
        updated_at: row.updated_at,
        published_at: row.published_at,
        taxonomies,
        options,
        performance: {
          content_id: row.id,
          impressions_count: row.impressions_count || 0,
          interactions_count: row.interactions_count || 0,
          skips_count: row.skips_count || 0,
          completions_count: row.completions_count || 0,
          avg_dwell_ms: row.avg_dwell_ms || 0,
          positive_signals_generated: row.positive_signals_generated || 0,
        },
      };
    });

    return { items, total };
  }

  /**
   * Update content status (APPROVE, REJECT, PAUSE, ARCHIVE, ACTIVATE)
   */
  static async updateContentStatus(
    contentId: string,
    status: ContentStatus,
    reviewerId?: string,
    notes?: string
  ): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `UPDATE content_items 
         SET status = $1, 
             published_at = CASE WHEN $1 = 'ACTIVE' THEN NOW() ELSE published_at END,
             updated_at = NOW() 
         WHERE id = $2`,
        [status, contentId]
      );

      if (reviewerId) {
        await client.query(
          `INSERT INTO content_reviews (content_id, reviewer_id, decision, notes)
           VALUES ($1, $2, $3, $4)`,
          [contentId, reviewerId, status, notes || null]
        );
      }

      await client.query('COMMIT');
      await InterestTaxonomyService.refreshContentCounts();
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Edit content item with versioning
   */
  static async updateContentItem(
    contentId: string,
    data: Partial<ContentItem>,
    editorId?: string
  ): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Fetch snapshot for versioning
      const { rows: currentRows } = await client.query('SELECT * FROM content_items WHERE id = $1', [contentId]);
      if (currentRows.length === 0) throw new Error('Content item not found');

      const current = currentRows[0];
      const newVersion = (current.version || 1) + 1;

      // Save old version snapshot
      await client.query(
        `INSERT INTO content_versions (content_id, version_number, snapshot, edited_by)
         VALUES ($1, $2, $3, $4)`,
        [contentId, current.version || 1, JSON.stringify(current), editorId || null]
      );

      // Update content item
      await client.query(
        `UPDATE content_items SET
          title_prompt = COALESCE($1, title_prompt),
          description = COALESCE($2, description),
          media_url = COALESCE($3, media_url),
          context_type = COALESCE($4, context_type),
          version = $5,
          updated_at = NOW()
        WHERE id = $6`,
        [data.title_prompt, data.description, data.media_url, data.context_type, newVersion, contentId]
      );

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}
