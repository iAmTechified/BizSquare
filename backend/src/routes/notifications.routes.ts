import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { NotificationService } from '../services/notification.service';
import { PushService } from '../services/push.service';

const router = Router();

/**
 * GET /api/v1/notifications
 * Returns list of in-app notifications and unread badge count with filter and pagination
 */
router.get('/', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const filter = req.query.filter === 'unread' ? 'unread' : 'all';
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 30;

    const data = await NotificationService.getUserNotifications(userId, { filter, page, limit });
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
 * Marks specified notifications (or all) as read
 */
router.post('/mark-read', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { notificationIds } = req.body;
    const result = await NotificationService.markAsRead(userId, notificationIds);
    res.json({
      success: true,
      data: result,
      message: 'Notifications marked as read',
    });
  } catch (err: any) {
    console.error('Error marking notifications as read:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/notifications/mark-unread
 * Marks specified notifications as unread
 */
router.post('/mark-unread', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { notificationIds } = req.body;
    if (!notificationIds || !Array.isArray(notificationIds) || notificationIds.length === 0) {
      res.status(400).json({ success: false, error: 'notificationIds array is required' });
      return;
    }

    const result = await NotificationService.markAsUnread(userId, notificationIds);
    res.json({
      success: true,
      data: result,
      message: 'Notifications marked as unread',
    });
  } catch (err: any) {
    console.error('Error marking notifications as unread:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
