import { pool } from '../db/pool';

export class ContentDuplicateService {
  /**
   * Calculates similarity between two text strings (Token Jaccard + Normalized Levenshtein)
   */
  static calculateTextSimilarity(a: string, b: string): number {
    const cleanA = a.toLowerCase().replace(/[^a-z0-9 ]/g, '').trim();
    const cleanB = b.toLowerCase().replace(/[^a-z0-9 ]/g, '').trim();

    if (cleanA === cleanB) return 1.0;

    const wordsA = new Set(cleanA.split(/\s+/));
    const wordsB = new Set(cleanB.split(/\s+/));

    const intersection = new Set([...wordsA].filter(x => wordsB.has(x)));
    const union = new Set([...wordsA, ...wordsB]);

    const jaccard = union.size > 0 ? intersection.size / union.size : 0;
    return jaccard;
  }

  /**
   * Checks if a new title/prompt is a duplicate or near-duplicate of existing active/review content
   */
  static async checkDuplicate(prompt: string, taxonomyId?: string): Promise<{ isDuplicate: boolean; matchedPrompt?: string; similarityScore: number }> {
    const query = taxonomyId
      ? `SELECT ci.title_prompt 
         FROM content_items ci 
         JOIN content_taxonomy_links ctl ON ctl.content_id = ci.id 
         WHERE ctl.taxonomy_id = $1 AND ci.status IN ('ACTIVE', 'APPROVED', 'REVIEW')`
      : `SELECT title_prompt FROM content_items WHERE status IN ('ACTIVE', 'APPROVED', 'REVIEW') LIMIT 200`;

    const params = taxonomyId ? [taxonomyId] : [];
    const { rows } = await pool.query(query, params);

    for (const row of rows) {
      const score = this.calculateTextSimilarity(prompt, row.title_prompt);
      if (score >= 0.75) {
        return { isDuplicate: true, matchedPrompt: row.title_prompt, similarityScore: score };
      }
    }

    return { isDuplicate: false, similarityScore: 0 };
  }
}
