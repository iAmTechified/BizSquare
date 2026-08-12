import { Router, Response } from 'express';
import { AuthRequest, authenticateJWT } from '../middleware/auth.middleware';
import { ContactService } from '../services/contact.service';

const router = Router();

router.use(authenticateJWT);

/**
 * GET /api/v1/contacts
 * Returns all contacts for authenticated user
 */
router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const includeArchived = req.query.include_archived === 'true';
    const contacts = await ContactService.getUserContacts(userId, includeArchived);
    res.json({ contacts });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/v1/contacts/:id
 * Updates contact properties
 */
router.put('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const contactId = req.params.id as string;
    const { isStarred, isArchived, notes, labels } = req.body;

    await ContactService.updateContact(userId, contactId, {
      isStarred: isStarred !== undefined ? Boolean(isStarred) : undefined,
      isArchived: isArchived !== undefined ? Boolean(isArchived) : undefined,
      notes,
      labels,
    });

    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/v1/contacts/bulk
 * Performs bulk actions on a list of contacts
 */
router.post('/bulk', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { contactIds, action, labelName } = req.body;
    if (!Array.isArray(contactIds) || !action) {
      return res.status(400).json({ error: 'Missing contactIds or action' });
    }

    await ContactService.bulkUpdate(userId, contactIds, action, labelName);
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/v1/contacts/merge
 * Merges two duplicate contacts
 */
router.post('/merge', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { primaryContactId, duplicateContactId } = req.body;
    if (!primaryContactId || !duplicateContactId) {
      return res.status(400).json({ error: 'Missing primaryContactId or duplicateContactId' });
    }

    await ContactService.mergeContacts(userId, primaryContactId, duplicateContactId);
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/v1/contacts/labels
 * Returns all custom contact labels
 */
router.get('/labels', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const labels = await ContactService.getLabels(userId);
    res.json({ labels });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/v1/contacts/labels
 * Creates a new custom label
 */
router.post('/labels', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { name, color } = req.body;
    if (!name) return res.status(400).json({ error: 'Label name is required' });

    const label = await ContactService.createLabel(userId, name, color);
    res.json({ success: true, label });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * DELETE /api/v1/contacts/labels/:id
 * Deletes a label without deleting contacts
 */
router.delete('/labels/:id', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    await ContactService.deleteLabel(userId, req.params.id as string);
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/v1/contacts/sync-device
 * Acknowledges device sync result
 */
router.post('/sync-device', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { contactUserIds, status } = req.body;
    if (!Array.isArray(contactUserIds)) {
      return res.status(400).json({ error: 'contactUserIds must be an array' });
    }

    await ContactService.acknowledgeDeviceSync(userId, contactUserIds, status || 'SYNCED');
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
