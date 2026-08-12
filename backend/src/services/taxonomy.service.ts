import { pool } from '../db/pool';

export class TaxonomyService {
  /**
   * Retrieves all categories with their micro-niches nested.
   */
  static async getCategoriesWithMicroNiches() {
    const { rows: categories } = await pool.query(
      `SELECT id, name, icon, sort_order FROM categories ORDER BY sort_order`
    );

    const { rows: microNiches } = await pool.query(
      `SELECT id, category_id, name FROM micro_niches WHERE is_active = true ORDER BY name`
    );

    return categories.map((cat: any) => ({
      ...cat,
      microNiches: microNiches.filter((mn: any) => mn.category_id === cat.id),
    }));
  }

  /**
   * Retrieves all micro-niches, optionally filtered by category.
   */
  static async getMicroNiches(categoryId?: string) {
    if (categoryId) {
      const { rows } = await pool.query(
        `SELECT mn.id, mn.category_id, mn.name, c.name AS category_name
         FROM micro_niches mn
         JOIN categories c ON c.id = mn.category_id
         WHERE mn.is_active = true AND mn.category_id = $1
         ORDER BY mn.name`,
        [categoryId]
      );
      return rows;
    }

    const { rows } = await pool.query(
      `SELECT mn.id, mn.category_id, mn.name, c.name AS category_name
       FROM micro_niches mn
       JOIN categories c ON c.id = mn.category_id
       WHERE mn.is_active = true
       ORDER BY c.sort_order, mn.name`
    );
    return rows;
  }

  /**
   * Gets micro-niches by an array of IDs.
   */
  static async getMicroNichesByIds(ids: string[]) {
    if (ids.length === 0) return [];
    const placeholders = ids.map((_, i) => `$${i + 1}`).join(', ');
    const { rows } = await pool.query(
      `SELECT mn.id, mn.category_id, mn.name, c.name AS category_name
       FROM micro_niches mn
       JOIN categories c ON c.id = mn.category_id
       WHERE mn.id IN (${placeholders})`,
      ids
    );
    return rows;
  }

  /**
   * Validates that a set of micro-niche IDs are valid and active.
   */
  static async validateMicroNicheIds(ids: string[]): Promise<boolean> {
    if (ids.length === 0 || ids.length > 3) return false;
    // Check for duplicates
    const unique = new Set(ids);
    if (unique.size !== ids.length) return false;

    const placeholders = ids.map((_, i) => `$${i + 1}`).join(', ');
    const { rows } = await pool.query(
      `SELECT COUNT(*) FROM micro_niches WHERE id IN (${placeholders}) AND is_active = true`,
      ids
    );
    return parseInt(rows[0].count, 10) === ids.length;
  }
}
