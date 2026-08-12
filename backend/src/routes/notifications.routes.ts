import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { NotificationService } from '../services/notification.service';

const router = Router();

/**
 * GET /api/v1/notifications
 * Returns list of in-app notifications and unread badge count
 */
router.get('/', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const data = await NotificationService.getUserNotifications(userId);
    res.json({
      success: true,
      data,
    });
  } catch (err: any) {
    console.error('Error fetching notifications:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/notifications/mark-read
 * Marks notifications as read
 */
router.post('/mark-read', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { notificationIds } = req.body;
    await NotificationService.markAsRead(userId, notificationIds);
    res.json({
      success: true,
      message: 'Notifications marked as read',
    });
  } catch (err: any) {
    console.error('Error marking notifications as read:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
