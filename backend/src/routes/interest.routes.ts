import { Router, Request, Response } from 'express';
import { InterestTaxonomyService } from '../services/interest_taxonomy.service';
import { InterestDemandService } from '../services/interest_demand.service';
import { WallSessionService } from '../services/wall_session.service';
import { InterestEventProcessor } from '../services/interest_event_processor';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();

// 1. Get Taxonomy Hierarchy
router.get('/taxonomies', async (req: Request, res: Response): Promise<void> => {
  try {
    const tree = await InterestTaxonomyService.getTaxonomyTree(true);
    res.status(200).json({ taxonomies: tree });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch taxonomies' });
  }
});

// 2. Get User Baseline Interests
router.get('/baseline', authenticateJWT, async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    const baseline = await InterestDemandService.getBaselineInterests(userId);
    res.status(200).json({ baseline });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch baseline interests' });
  }
});

// 3. Update User Baseline Interests (Profile -> Interests -> My Interests)
router.put('/baseline', authenticateJWT, async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    const { taxonomyIds } = req.body;
    if (!Array.isArray(taxonomyIds)) {
      res.status(400).json({ error: 'taxonomyIds must be an array of UUIDs' });
      return;
    }
    await InterestDemandService.setBaselineInterests(userId, taxonomyIds);
    res.status(200).json({ message: 'Baseline interests updated successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to update baseline interests' });
  }
});

// 4. Get or Create Daily Interactive Wall Session
router.get('/wall/session', authenticateJWT, async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    const targetCount = parseInt(req.query.targetCount as string, 10) || 5;

    const session = await WallSessionService.getOrCreateDailySession({
      userId,
      targetCount,
    });
    res.status(200).json(session);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to start daily wall session' });
  }
});

// 5. Submit Wall Interaction Event (Idempotent)
router.post('/wall/interaction', authenticateJWT, async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    const { eventId, sessionId, contentId, format, optionId, interactionType, dwellMs, metadata } = req.body;

    if (!contentId || !format || !optionId || !interactionType) {
      res.status(400).json({ error: 'Missing required interaction fields: contentId, format, optionId, interactionType' });
      return;
    }

    const result = await InterestEventProcessor.processInteractionEvent({
      eventId,
      userId,
      sessionId,
      contentId,
      format,
      optionId,
      interactionType,
      dwellMs: dwellMs || 0,
      metadata: metadata || {},
    });

    res.status(200).json({ status: 'success', eventId: result.eventId, signalsGenerated: result.signalsCount });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to process interaction event' });
  }
});

// 6. Complete Daily Wall Session
router.post('/wall/session/complete', authenticateJWT, async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    const { sessionId } = req.body;

    if (!sessionId) {
      res.status(400).json({ error: 'sessionId is required' });
      return;
    }

    await WallSessionService.completeSession(sessionId, userId);
    res.status(200).json({ message: 'Wall session completed successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to complete wall session' });
  }
});

// 7. Get Concentrated Current Demand Output Payload
router.get('/demand/current', authenticateJWT, async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    const currentDemand = await InterestDemandService.getCurrentDemand(userId);
    res.status(200).json(currentDemand);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch current demand' });
  }
});

export default router;
