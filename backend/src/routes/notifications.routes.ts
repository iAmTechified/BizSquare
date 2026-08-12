import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { NotificationService } from '../services/notification.service';
import { NotificationFoundationService } from '../services/notification_foundation.service';

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

/**
 * GET /api/v1/notifications/preferences
 * Get user notification category preferences (Section 9)
 */
router.get('/preferences', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const preferences = await NotificationFoundationService.getUserPreferences(userId);
    res.json({ success: true, preferences });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/v1/notifications/preferences
 * Update user notification category preferences (Section 9)
 */
router.put('/preferences', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { preferences } = req.body;
    if (!preferences || typeof preferences !== 'object') {
      res.status(400).json({ success: false, error: 'preferences object is required' });
      return;
    }

    const updated = await NotificationFoundationService.updateUserPreferences(userId, preferences);
    res.json({ success: true, preferences: updated, message: 'Preferences updated' });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/notifications/analytics/event
 * Log notification telemetry event (Section 8)
 */
router.post('/analytics/event', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { notificationId, eventType, source, metadata } = req.body;

    if (!eventType || typeof eventType !== 'string') {
      res.status(400).json({ success: false, error: 'eventType is required' });
      return;
    }

    await NotificationFoundationService.trackAnalytics({
      userId,
      notificationId,
      eventType,
      source: source || 'BACKEND',
      metadata: metadata || {},
    });

    res.json({ success: true, message: 'Notification event tracked.' });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/v1/notifications/admin/send
 * Admin targeted or broadcast notification dispatch (Section 1 Source B)
 */
router.post('/admin/send', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { recipientUserIds, broadcastAll, title, body, category, priority, deepLink } = req.body;

    if (!title || !body) {
      res.status(400).json({ success: false, error: 'title and body are required' });
      return;
    }

    const result = await NotificationFoundationService.sendAdminNotification({
      recipientUserIds,
      broadcastAll,
      title,
      body,
      category,
      priority,
      deepLink,
    });

    res.json({ success: true, dispatchedCount: result.dispatchedCount, message: 'Admin notifications sent' });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
