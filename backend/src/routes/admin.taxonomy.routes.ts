import { Router, Request, Response } from 'express';
import { pool } from '../db/pool';

const router = Router();

/**
 * GET /api/v1/admin/taxonomy
 * List all categories with nested micro-niches
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const { rows: cats } = await pool.query(
      `SELECT id, name, icon, sort_order FROM categories ORDER BY sort_order ASC`
    );
    const { rows: niches } = await pool.query(
      `SELECT id, category_id, name, is_active FROM micro_niches ORDER BY category_id, name ASC`
    );
    const result = cats.map(cat => ({
      ...cat,
      micro_niches: niches.filter(n => n.category_id === cat.id),
    }));
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/v1/admin/taxonomy/niches
 * Create a new micro-niche
 * Body: { id: string, category_id: string, name: string }
 */
router.post('/niches', async (req: Request, res: Response) => {
  const { id, category_id, name } = req.body;
  if (!id || !category_id || !name) {
    return res.status(400).json({ error: 'id, category_id, and name are required' });
  }
  try {
    const { rows } = await pool.query(
      `INSERT INTO micro_niches (id, category_id, name) VALUES ($1, $2, $3) RETURNING *`,
      [id, category_id, name]
    );
    res.status(201).json(rows[0]);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PUT /api/v1/admin/taxonomy/niches/:id
 * Edit a micro-niche name or active status
 * Body: { name?: string, is_active?: boolean }
 */
router.put('/niches/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { name, is_active } = req.body;
  try {
    const { rows } = await pool.query(
      `UPDATE micro_niches SET
        name = COALESCE($1, name),
        is_active = COALESCE($2, is_active)
       WHERE id = $3 RETURNING *`,
      [name ?? null, is_active ?? null, id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Niche not found' });
    res.json(rows[0]);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * DELETE /api/v1/admin/taxonomy/niches/:id
 * Soft-delete: sets is_active = false
 */
router.delete('/niches/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    await pool.query(`UPDATE micro_niches SET is_active = false WHERE id = $1`, [id]);
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/v1/admin/taxonomy/categories
 * Create a new category
 * Body: { id: string, name: string, icon?: string, sort_order?: number }
 */
router.post('/categories', async (req: Request, res: Response) => {
  const { id, name, icon, sort_order } = req.body;
  if (!id || !name) {
    return res.status(400).json({ error: 'id and name are required' });
  }
  try {
    const { rows } = await pool.query(
      `INSERT INTO categories (id, name, icon, sort_order) VALUES ($1, $2, $3, $4) RETURNING *`,
      [id, name, icon ?? 'store', sort_order ?? 0]
    );
    res.status(201).json(rows[0]);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
