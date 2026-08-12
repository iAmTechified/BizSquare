import { pool } from './pool';

export async function migrateV15MediaPipeline(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Create media_records table for secure media lifecycle tracking
    await client.query(`
      CREATE TABLE IF NOT EXISTS media_records (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        source VARCHAR(30) NOT NULL DEFAULT 'USER',
        media_type VARCHAR(20) NOT NULL,
        mime_type VARCHAR(100) NOT NULL,
        file_size BIGINT NOT NULL,
        original_filename VARCHAR(255),
        storage_key VARCHAR(500) NOT NULL,
        thumbnail_key VARCHAR(500),
        width INT,
        height INT,
        duration_seconds INT,
        status VARCHAR(30) NOT NULL DEFAULT 'UPLOADING',
        processing_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
        moderation_status VARCHAR(30) NOT NULL DEFAULT 'PENDING_REVIEW',
        moderation_reason TEXT,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Indexes for efficient querying
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_mr_owner ON media_records(owner_id);
      CREATE INDEX IF NOT EXISTS idx_mr_status ON media_records(status);
      CREATE INDEX IF NOT EXISTS idx_mr_moderation ON media_records(moderation_status);
    `);

    // 2. Link media_id to spotlight_campaigns if missing
    await client.query(`
      ALTER TABLE spotlight_campaigns
      ADD COLUMN IF NOT EXISTS media_id UUID REFERENCES media_records(id) ON DELETE SET NULL;
    `);

    await client.query('COMMIT');
    console.log('[Migration] V15 Media Pipeline schema executed successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Migration] Failed to execute V15 Media Pipeline migration:', error);
  } finally {
    client.release();
  }
}
