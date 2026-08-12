import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { PollsService } from '../services/polls.service';

const router = Router();

router.get('/active', authenticateJWT, async (req: AuthRequest, res: Response) => {
  try {
    const polls = await PollsService.getActivePolls(req.user.id);
    res.json({ polls });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/swipe', authenticateJWT, async (req: AuthRequest, res: Response) => {
  try {
    const { pollId, response } = req.body;
    if (pollId === undefined || response === undefined) {
      return res.status(400).json({ error: 'Missing pollId or response boolean' });
    }
    
    const result = await PollsService.submitSwipe(req.user.id, pollId, response);
    res.json({ success: true, swipe: result });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
