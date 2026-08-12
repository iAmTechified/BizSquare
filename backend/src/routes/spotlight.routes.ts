import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { SpotlightService } from '../services/spotlight.service';

const router = Router();

/**
 * GET /api/v1/spotlight/current
 * Returns server-authoritative current Spotlight state
 */
router.get('/current', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const data = await SpotlightService.getCurrentSpotlight(userId);
    res.json({
      success: true,
      data,
    });
  } catch (err: any) {
    console.error('Error fetching current spotlight:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/spotlight/submit
 * Idempotent submission when it is the user's turn
 */
router.post('/submit', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { title, promoText, caption, flyerUrl, idempotencyKey } = req.body;

    if (!title || !promoText) {
      res.status(400).json({ success: false, error: 'Title and promo text are required' });
      return;
    }

    const result = await SpotlightService.submitSpotlight(userId, {
      title,
      promoText,
      caption: caption || '',
      flyerUrl,
      idempotencyKey,
    });

    res.json(result);
  } catch (err: any) {
    console.error('Error submitting spotlight:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/spotlight/participate
 * Logs that the user has shared the active spotlight campaign to WhatsApp
 */
router.post('/participate', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { campaignId } = req.body;
    if (!campaignId) {
      res.status(400).json({ success: false, error: 'Missing campaignId' });
      return;
    }
    const result = await SpotlightService.participate(userId, campaignId);
    res.json(result);
  } catch (err: any) {
    console.error('Error participating in spotlight:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/v1/spotlight/history
 * Returns Spotlight participation history for "Mine" and "Others"
 */
router.get('/history', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const history = await SpotlightService.getHistory(userId);
    res.json({
      success: true,
      data: history,
    });
  } catch (err: any) {
    console.error('Error fetching spotlight history:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/v1/spotlight/campaign/:id/participants
 * Returns authorized list of participants for a given campaign
 */
router.get('/campaign/:id/participants', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const campaignId = req.params.id as string;
    if (!campaignId) {
      res.status(400).json({ success: false, error: 'Missing campaignId' });
      return;
    }
    const participants = await SpotlightService.getCampaignParticipants(campaignId);
    res.json({
      success: true,
      data: participants,
    });
  } catch (err: any) {
    console.error('Error fetching spotlight participants:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
