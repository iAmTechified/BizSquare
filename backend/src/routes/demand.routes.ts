import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { DemandService } from '../services/demand.service';

const router = Router();

/**
 * POST /api/v1/demand/baseline
 * Creates baseline demand from onboarding Step 5 interests.
 */
router.post('/baseline', authenticateJWT, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user.id;
    const { microNicheIds } = req.body;

    if (!microNicheIds || !Array.isArray(microNicheIds) || microNicheIds.length === 0) {
      return res.status(400).json({ error: 'At least one interest micro-niche is required' });
    }

    if (microNicheIds.length > 5) {
      return res.status(400).json({ error: 'Maximum 5 interests allowed' });
    }

    const result = await DemandService.createBaselineDemand(userId, microNicheIds);
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/v1/demand/dynamic
 * Records a Daily Wall interaction as dynamic demand.
 */
router.post('/dynamic', authenticateJWT, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user.id;
    const { microNicheId, interactionType } = req.body;

    if (!microNicheId || !interactionType) {
      return res.status(400).json({ error: 'microNicheId and interactionType are required' });
    }

    if (!['positive', 'negative', 'skip'].includes(interactionType)) {
      return res.status(400).json({ error: 'interactionType must be positive, negative, or skip' });
    }

    const result = await DemandService.createDynamicDemand(userId, microNicheId, interactionType);
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/v1/demand/active
 * Returns a user's active demand profile (dynamic + baseline).
 */
router.get('/active', authenticateJWT, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user.id;
    const demand = await DemandService.getActiveDemand(userId);
    res.json(demand);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
