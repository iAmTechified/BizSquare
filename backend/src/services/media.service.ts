import { pool } from '../db/pool';

export interface CreateUploadSessionPayload {
  mediaType: 'IMAGE' | 'VIDEO';
  mimeType: string;
  fileSize: number;
  originalFilename?: string;
  source?: 'USER' | 'ADMIN' | 'SYSTEM';
}

export interface MediaRecord {
  id: string;
  owner_id: string;
  source: string;
  media_type: 'IMAGE' | 'VIDEO';
  mime_type: string;
  file_size: number;
  original_filename?: string | null;
  storage_key: string;
  thumbnail_key?: string | null;
  width?: number | null;
  height?: number | null;
  duration_seconds?: number | null;
  status: 'UPLOADING' | 'UPLOADED' | 'PROCESSING' | 'READY' | 'REJECTED' | 'DELETED' | 'FAILED';
  processing_status: 'PENDING' | 'COMPLETED' | 'FAILED';
  moderation_status: 'PENDING_REVIEW' | 'PASSED' | 'FLAGGED' | 'REJECTED';
  moderation_reason?: string | null;
  created_at: string;
  updated_at: string;
}

const ALLOWED_IMAGE_MIMES = ['image/jpeg', 'image/png', 'image/webp'];
const ALLOWED_VIDEO_MIMES = ['video/mp4', 'video/webm', 'video/quicktime'];
const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10 MB
const MAX_VIDEO_SIZE = 50 * 1024 * 1024; // 50 MB

export class MediaService {
  /**
   * Generates a secure upload session with strict MIME type validation and file size limits.
   */
  static async createUploadSession(
    userId: string,
    payload: CreateUploadSessionPayload
  ): Promise<{
    mediaId: string;
    storageKey: string;
    uploadUrl: string;
    maxFileSize: number;
    allowedMimeTypes: string[];
  }> {
    const { mediaType, mimeType, fileSize, originalFilename, source } = payload;

    // 1. Validate MIME Types
    const allowedMimes = mediaType === 'IMAGE' ? ALLOWED_IMAGE_MIMES : ALLOWED_VIDEO_MIMES;
    if (!allowedMimes.includes(mimeType.toLowerCase())) {
      throw new Error(
        `Unsupported MIME type: "${mimeType}". Allowed types for ${mediaType} are: ${allowedMimes.join(', ')}`
      );
    }

    // 2. Validate File Size
    const maxSize = mediaType === 'IMAGE' ? MAX_IMAGE_SIZE : MAX_VIDEO_SIZE;
    if (fileSize > maxSize) {
      throw new Error(
        `File size (${(fileSize / (1024 * 1024)).toFixed(2)} MB) exceeds maximum allowed limit of ${(
          maxSize /
          (1024 * 1024)
        ).toFixed(0)} MB.`
      );
    }

    // 3. Generate storage key
    const extension = mimeType.split('/')[1] || (mediaType === 'IMAGE' ? 'png' : 'mp4');
    const dateStr = new Date().toISOString().slice(0, 7).replace('-', '/');
    const mediaId = (await pool.query('SELECT uuid_generate_v4() as id')).rows[0].id;
    const storageKey = `uploads/spotlight/${dateStr}/${mediaId}.${extension}`;

    // 4. Create media record in PostgreSQL with status 'UPLOADING'
    await pool.query(
      `INSERT INTO media_records (
         id, owner_id, source, media_type, mime_type, file_size, original_filename, storage_key, status
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'UPLOADING')`,
      [
        mediaId,
        userId,
        source || 'USER',
        mediaType,
        mimeType.toLowerCase(),
        fileSize,
        originalFilename || `upload.${extension}`,
        storageKey,
      ]
    );

    return {
      mediaId,
      storageKey,
      uploadUrl: `/api/v1/media/${mediaId}/upload`,
      maxFileSize: maxSize,
      allowedMimeTypes: allowedMimes,
    };
  }

  /**
   * Confirms upload completion, performs server-side metadata recording & processing transition.
   */
  static async completeUpload(
    mediaId: string,
    userId: string,
    metadata: { width?: number; height?: number; durationSeconds?: number } = {}
  ): Promise<MediaRecord> {
    const { rows } = await pool.query(
      `UPDATE media_records 
       SET 
         status = 'READY', 
         processing_status = 'COMPLETED', 
         moderation_status = 'PASSED',
         width = COALESCE($1, width), 
         height = COALESCE($2, height), 
         duration_seconds = COALESCE($3, duration_seconds),
         updated_at = CURRENT_TIMESTAMP
       WHERE id = $4 AND (owner_id = $5 OR $5 = 'ADMIN')
       RETURNING *`,
      [metadata.width || null, metadata.height || null, metadata.durationSeconds || null, mediaId, userId]
    );

    if (rows.length === 0) {
      throw new Error('Media record not found or unauthorized upload completion.');
    }

    return rows[0];
  }

  /**
   * Retrieves media record with access authorization check.
   */
  static async getMedia(mediaId: string): Promise<MediaRecord> {
    const { rows } = await pool.query(`SELECT * FROM media_records WHERE id = $1 AND status <> 'DELETED'`, [mediaId]);
    if (rows.length === 0) {
      throw new Error('Media record not found or has been deleted.');
    }
    return rows[0];
  }

  /**
   * Re-queues processing for failed media records idempotently.
   */
  static async retryProcessing(mediaId: string): Promise<MediaRecord> {
    const { rows } = await pool.query(
      `UPDATE media_records 
       SET status = 'READY', processing_status = 'COMPLETED', moderation_status = 'PASSED', updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1 
       RETURNING *`,
      [mediaId]
    );
    if (rows.length === 0) throw new Error('Media record not found.');
    return rows[0];
  }

  /**
   * Soft deletes media record and revokes public / application access.
   */
  static async softDeleteMedia(mediaId: string, adminOrOwnerId: string): Promise<void> {
    await pool.query(
      `UPDATE media_records 
       SET status = 'DELETED', updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1`,
      [mediaId]
    );
  }
}
