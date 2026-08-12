import { Router, Request, Response } from 'express';
import { TaxonomyService } from '../services/taxonomy.service';

const router = Router();

/**
 * GET /api/v1/taxonomy/categories
 * Returns all categories with nested micro-niches.
 */
router.get('/categories', async (_req: Request, res: Response) => {
  try {
    const categories = await TaxonomyService.getCategoriesWithMicroNiches();
    res.json({ categories });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/v1/taxonomy/micro-niches
 * Returns all micro-niches, optionally filtered by categoryId query param.
 */
router.get('/micro-niches', async (req: Request, res: Response) => {
  try {
    const categoryId = req.query.categoryId as string | undefined;
    const microNiches = await TaxonomyService.getMicroNiches(categoryId);
    res.json({ microNiches });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
