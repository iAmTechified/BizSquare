import { pool } from './pool';

export async function migrateV13SpotlightOps(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Add status and override tracking columns to spotlight_campaigns if missing
    await client.query(`
      ALTER TABLE spotlight_campaigns
      ADD COLUMN IF NOT EXISTS status VARCHAR(32) DEFAULT 'active',
      ADD COLUMN IF NOT EXISTS override_reason TEXT,
      ADD COLUMN IF NOT EXISTS overridden_by UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS disapproved_by UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS stopped_by UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS stopped_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS is_override BOOLEAN DEFAULT FALSE;
    `);

    // 2. Add indexes for efficient querying
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sc_status ON spotlight_campaigns(status);
      CREATE INDEX IF NOT EXISTS idx_sc_submission_status ON spotlight_campaigns(submission_status);
      CREATE INDEX IF NOT EXISTS idx_sc_is_override ON spotlight_campaigns(is_override);
    `);

    await client.query('COMMIT');
    console.log('[Migration] V13 Spotlight Operations schema verified successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Migration] Failed to execute V13 Spotlight Operations migration:', error);
  } finally {
    client.release();
  }
}
