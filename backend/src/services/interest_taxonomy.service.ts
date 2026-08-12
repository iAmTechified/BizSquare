import { pool } from '../db/pool';
import { InterestTaxonomyNode, TaxonomyRelationship } from '../types/interest_engine.types';

export class InterestTaxonomyService {
  /**
   * Retrieves full hierarchical taxonomy tree
   */
  static async getTaxonomyTree(activeOnly: boolean = true): Promise<InterestTaxonomyNode[]> {
    const whereClause = activeOnly ? 'WHERE is_active = TRUE' : '';
    const query = `
      SELECT 
        id, slug, name, parent_id, description, context_type,
        icon, sort_order, is_active, aliases, content_count, active_content_count
      FROM interest_taxonomies
      ${whereClause}
      ORDER BY sort_order ASC, name ASC
    `;
    const { rows } = await pool.query(query);

    const nodeMap = new Map<string, InterestTaxonomyNode>();
    const roots: InterestTaxonomyNode[] = [];

    rows.forEach(r => {
      nodeMap.set(r.id, { ...r, children: [] });
    });

    rows.forEach(r => {
      const node = nodeMap.get(r.id)!;
      if (r.parent_id && nodeMap.has(r.parent_id)) {
        nodeMap.get(r.parent_id)!.children!.push(node);
      } else {
        roots.push(node);
      }
    });

    return roots;
  }

  /**
   * Get flat list of all taxonomies
   */
  static async getAllTaxonomies(activeOnly: boolean = true): Promise<InterestTaxonomyNode[]> {
    const whereClause = activeOnly ? 'WHERE is_active = TRUE' : '';
    const query = `
      SELECT 
        id, slug, name, parent_id, description, context_type,
        icon, sort_order, is_active, aliases, content_count, active_content_count
      FROM interest_taxonomies
      ${whereClause}
      ORDER BY sort_order ASC, name ASC
    `;
    const { rows } = await pool.query(query);
    return rows;
  }

  /**
   * Get taxonomy by ID or slug
   */
  static async getTaxonomyByIdOrSlug(identifier: string): Promise<InterestTaxonomyNode | null> {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(identifier);
    const query = isUuid
      ? 'SELECT * FROM interest_taxonomies WHERE id = $1'
      : 'SELECT * FROM interest_taxonomies WHERE slug = $1';
    const { rows } = await pool.query(query, [identifier]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * Get soft semantic relationships for a taxonomy node
   */
  static async getRelationships(taxonomyId: string): Promise<TaxonomyRelationship[]> {
    const query = `
      SELECT 
        r.id, r.source_id, r.target_id, r.relationship_type, r.weight,
        t.name as target_name, t.slug as target_slug
      FROM interest_taxonomy_relationships r
      JOIN interest_taxonomies t ON t.id = r.target_id
      WHERE r.source_id = $1
      ORDER BY r.weight DESC
    `;
    const { rows } = await pool.query(query, [taxonomyId]);
    return rows;
  }

  /**
   * Create or update taxonomy node
   */
  static async upsertTaxonomy(data: Partial<InterestTaxonomyNode>): Promise<InterestTaxonomyNode> {
    const { slug, name, parent_id, description, context_type, icon, sort_order, aliases, is_active } = data;
    const query = `
      INSERT INTO interest_taxonomies (
        slug, name, parent_id, description, context_type, icon, sort_order, aliases, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ON CONFLICT (slug) DO UPDATE SET
        name = EXCLUDED.name,
        parent_id = EXCLUDED.parent_id,
        description = EXCLUDED.description,
        context_type = EXCLUDED.context_type,
        icon = EXCLUDED.icon,
        sort_order = EXCLUDED.sort_order,
        aliases = EXCLUDED.aliases,
        is_active = EXCLUDED.is_active,
        updated_at = NOW()
      RETURNING *
    `;
    const { rows } = await pool.query(query, [
      slug,
      name,
      parent_id || null,
      description || null,
      context_type || 'general',
      icon || 'category',
      sort_order || 0,
      aliases || [],
      is_active !== undefined ? is_active : true,
    ]);
    return rows[0];
  }

  /**
   * Link soft semantic relationship between two nodes
   */
  static async addRelationship(
    sourceId: string,
    targetId: string,
    relationshipType: string = 'related',
    weight: number = 0.75
  ): Promise<void> {
    const query = `
      INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (source_id, target_id, relationship_type) DO UPDATE SET
        weight = EXCLUDED.weight
    `;
    await pool.query(query, [sourceId, targetId, relationshipType, weight]);
  }

  /**
   * Recalculates content counts across all taxonomies
   */
  static async refreshContentCounts(): Promise<void> {
    const query = `
      UPDATE interest_taxonomies t
      SET 
        content_count = (SELECT COUNT(*) FROM content_taxonomy_links ctl WHERE ctl.taxonomy_id = t.id),
        active_content_count = (
          SELECT COUNT(*) 
          FROM content_taxonomy_links ctl 
          JOIN content_items ci ON ci.id = ctl.content_id 
          WHERE ctl.taxonomy_id = t.id AND ci.status = 'ACTIVE'
        )
    `;
    await pool.query(query);
  }
}
