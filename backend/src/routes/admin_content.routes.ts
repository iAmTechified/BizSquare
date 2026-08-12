import { Router, Request, Response } from 'express';
import { InterestTaxonomyService } from '../services/interest_taxonomy.service';
import { ContentBankService } from '../services/content_bank.service';
import { ContentGenerationService } from '../services/content_generation.service';
import { ContentReviewService } from '../services/content_review.service';
import { ContentAnalyticsService } from '../services/content_analytics.service';
import { ContentFormat, ContentStatus } from '../types/interest_engine.types';

const router = Router();

// 1. Overview Metrics
router.get('/overview', async (req: Request, res: Response): Promise<void> => {
  try {
    const metrics = await ContentAnalyticsService.getOverviewMetrics();
    res.status(200).json(metrics);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch overview metrics' });
  }
});

// 2. Taxonomies List & Tree
router.get('/taxonomies', async (req: Request, res: Response): Promise<void> => {
  try {
    const list = await InterestTaxonomyService.getAllTaxonomies(false);
    const tree = await InterestTaxonomyService.getTaxonomyTree(false);
    res.status(200).json({ list, tree });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch taxonomies' });
  }
});

// 3. Upsert Taxonomy Node
router.post('/taxonomies', async (req: Request, res: Response): Promise<void> => {
  try {
    const node = await InterestTaxonomyService.upsertTaxonomy(req.body);
    res.status(200).json({ node });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to upsert taxonomy' });
  }
});

// 4. Link Semantic Relationship
router.post('/taxonomies/relationship', async (req: Request, res: Response): Promise<void> => {
  try {
    const { sourceId, targetId, relationshipType, weight } = req.body;
    if (!sourceId || !targetId) {
      res.status(400).json({ error: 'sourceId and targetId are required' });
      return;
    }
    await InterestTaxonomyService.addRelationship(sourceId, targetId, relationshipType, weight || 0.75);
    res.status(200).json({ message: 'Relationship established successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to establish relationship' });
  }
});

// 5. Query Content Bank
router.get('/content', async (req: Request, res: Response): Promise<void> => {
  try {
    const taxonomyId = req.query.taxonomyId as string;
    const format = req.query.format as ContentFormat;
    const status = req.query.status as ContentStatus;
    const contextType = req.query.contextType as string;
    const search = req.query.search as string;
    const limit = parseInt(req.query.limit as string, 10) || 50;
    const offset = parseInt(req.query.offset as string, 10) || 0;

    const result = await ContentBankService.getContentItems({
      taxonomyId,
      format,
      status,
      contextType,
      search,
      limit,
      offset,
    });
    res.status(200).json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to query content items' });
  }
});

// 6. Trigger AI Batch Generation
router.post('/content/generate', async (req: Request, res: Response): Promise<void> => {
  try {
    const { taxonomyId, formats, quantity, contextType, targetAudience, tone, createdBy } = req.body;
    if (!taxonomyId) {
      res.status(400).json({ error: 'taxonomyId is required' });
      return;
    }

    const result = await ContentGenerationService.generateBatch({
      taxonomyId,
      formats: formats || ['THIS_OR_THAT', 'PICK_ONE', 'WOULD_YOU', 'REACTION_CARD', 'SCENARIO'],
      quantity: quantity || 10,
      contextType: contextType || 'mixed',
      targetAudience: targetAudience || 'general',
      tone: tone || 'balanced',
      createdBy,
    });

    res.status(200).json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to execute content generation batch' });
  }
});

// 7. Get Generation Batches History
router.get('/content/batches', async (req: Request, res: Response): Promise<void> => {
  try {
    const batches = await ContentReviewService.getGenerationBatches(25);
    res.status(200).json({ batches });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch generation history' });
  }
});

// 8. Update Individual Content Status (APPROVE, REJECT, PAUSE, ARCHIVE)
router.post('/content/:id/status', async (req: Request, res: Response): Promise<void> => {
  try {
    const contentId = req.params.id as string;
    const { status, reviewerId, notes } = req.body;
    if (!status) {
      res.status(400).json({ error: 'status is required' });
      return;
    }
    await ContentBankService.updateContentStatus(contentId, status, reviewerId, notes);
    res.status(200).json({ message: `Content item status updated to ${status}` });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to update content status' });
  }
});

// 9. Bulk Review Actions
router.post('/content/bulk-review', async (req: Request, res: Response): Promise<void> => {
  try {
    const { contentIds, action, reviewerId, notes } = req.body;
    if (!Array.isArray(contentIds) || !action) {
      res.status(400).json({ error: 'contentIds array and action are required' });
      return;
    }
    const result = await ContentReviewService.bulkReviewAction(contentIds, action, reviewerId, notes);
    res.status(200).json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to perform bulk review action' });
  }
});

// 10. Edit Content Item with Snapshot Versioning
router.patch('/content/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const contentId = req.params.id as string;
    const { editorId, ...data } = req.body;
    await ContentBankService.updateContentItem(contentId, data, editorId);
    res.status(200).json({ message: 'Content item updated with new version' });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to edit content item' });
  }
});

// 11. Bank Health & Taxonomy Coverage Heatmap
router.get('/health-coverage', async (req: Request, res: Response): Promise<void> => {
  try {
    const coverage = await ContentAnalyticsService.getBankHealthCoverage();
    res.status(200).json(coverage);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch bank health coverage' });
  }
});

// 12. Wall & Format Performance Analytics
router.get('/analytics', async (req: Request, res: Response): Promise<void> => {
  try {
    const analytics = await ContentAnalyticsService.getWallAnalytics();
    res.status(200).json(analytics);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch performance analytics' });
  }
});

export default router;
