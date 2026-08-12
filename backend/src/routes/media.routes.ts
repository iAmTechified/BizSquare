import { Router, Response } from 'express';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { MediaService } from '../services/media.service';

const router = Router();

/**
 * POST /api/v1/media/upload-session
 * Generates a secure upload session token with MIME type validation and file size limits.
 */
router.post('/upload-session', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { mediaType, mimeType, fileSize, originalFilename, source } = req.body;

    if (!mediaType || !mimeType || !fileSize) {
      res.status(400).json({ success: false, error: 'mediaType, mimeType, and fileSize are required.' });
      return;
    }

    const session = await MediaService.createUploadSession(userId, {
      mediaType,
      mimeType,
      fileSize: parseInt(fileSize, 10),
      originalFilename,
      source,
    });

    res.json({
      success: true,
      session,
    });
  } catch (err: any) {
    console.error('Upload session error:', err);
    res.status(400).json({ success: false, error: err.message || 'Failed to create upload session.' });
  }
});

/**
 * POST /api/v1/media/:id/complete
 * Confirms media upload completion and triggers server-side processing transition.
 */
router.post('/:id/complete', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const mediaId = req.params.id as string;
    const { width, height, durationSeconds } = req.body;

    const media = await MediaService.completeUpload(mediaId, userId, {
      width: width ? parseInt(width, 10) : undefined,
      height: height ? parseInt(height, 10) : undefined,
      durationSeconds: durationSeconds ? parseInt(durationSeconds, 10) : undefined,
    });

    res.json({
      success: true,
      message: 'Media upload completed successfully and processed.',
      media,
    });
  } catch (err: any) {
    console.error('Complete upload error:', err);
    res.status(400).json({ success: false, error: err.message || 'Failed to complete upload.' });
  }
});

/**
 * GET /api/v1/media/:id
 * Fetches media record details and authenticated stream reference.
 */
router.get('/:id', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const mediaId = req.params.id as string;
    const media = await MediaService.getMedia(mediaId);
    res.json({
      success: true,
      media,
    });
  } catch (err: any) {
    res.status(404).json({ success: false, error: err.message || 'Media not found.' });
  }
});

/**
 * POST /api/v1/media/:id/retry
 * Idempotently retries processing for failed media records.
 */
router.post('/:id/retry', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const mediaId = req.params.id as string;
    const media = await MediaService.retryProcessing(mediaId);
    res.json({
      success: true,
      message: 'Media processing retried successfully.',
      media,
    });
  } catch (err: any) {
    res.status(400).json({ success: false, error: err.message || 'Failed to retry media processing.' });
  }
});

/**
 * DELETE /api/v1/media/:id
 * Soft deletes media record and revokes access.
 */
router.delete('/:id', authenticateJWT, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const mediaId = req.params.id as string;
    await MediaService.softDeleteMedia(mediaId, userId);
    res.json({
      success: true,
      message: 'Media soft deleted successfully.',
    });
  } catch (err: any) {
    res.status(400).json({ success: false, error: err.message || 'Failed to delete media.' });
  }
});

export default router;
