import { pool } from '../db/pool';
import { ContentBankService } from './content_bank.service';
import { ContentStatus } from '../types/interest_engine.types';

export class ContentReviewService {
  /**
   * Bulk approve, reject, or pause content items
   */
  static async bulkReviewAction(
    contentIds: string[],
    action: 'APPROVE' | 'REJECT' | 'PAUSE' | 'ARCHIVE',
    reviewerId?: string,
    notes?: string
  ): Promise<{ affected: number }> {
    const targetStatus: ContentStatus = 
      action === 'APPROVE' ? 'ACTIVE' :
      action === 'REJECT' ? 'REJECTED' :
      action === 'PAUSE' ? 'PAUSED' : 'ARCHIVED';

    for (const id of contentIds) {
      await ContentBankService.updateContentStatus(id, targetStatus, reviewerId, notes);
    }

    return { affected: contentIds.length };
  }

  /**
   * Get generation batches history
   */
  static async getGenerationBatches(limit: number = 20): Promise<any[]> {
    const query = `
      SELECT 
        cgb.*,
        t.name as taxonomy_name, t.slug as taxonomy_slug
      FROM content_generation_batches cgb
      LEFT JOIN interest_taxonomies t ON t.id = cgb.taxonomy_id
      ORDER BY cgb.created_at DESC
      LIMIT $1
    `;
    const { rows } = await pool.query(query, [limit]);
    return rows;
  }
}
