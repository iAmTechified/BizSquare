import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { SpotlightService } from '../services/spotlight.service';

const router = Router();

/**
 * GET /api/v1/spotlight/current
 * Returns current Spotlight state (user's turn vs not user's turn, flyer, participants)
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
 * POST /api/v1/spotlight/participate
 * Logs that the user has shared the current spotlight campaign on WhatsApp
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
    res.json({
      success: true,
      data: result,
    });
  } catch (err: any) {
    console.error('Error participating in spotlight:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/spotlight/my-content
 * Sets custom flyer, promo text, and caption when it's user's turn in Spotlight
 */
router.post('/my-content', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { title, promoText, caption, flyerUrl } = req.body;
    if (!title || !promoText || !caption) {
      res.status(400).json({ success: false, error: 'Missing required content fields' });
      return;
    }
    await SpotlightService.setMyContent(userId, title, promoText, caption, flyerUrl);
    res.json({
      success: true,
      message: 'Spotlight content updated successfully',
    });
  } catch (err: any) {
    console.error('Error setting spotlight content:', err);
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

export default router;
