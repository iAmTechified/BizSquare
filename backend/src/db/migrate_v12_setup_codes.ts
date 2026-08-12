import { pool } from './pool';

export async function migrateV12SetupCodes(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Ensure verification_codes table exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS verification_codes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        code VARCHAR(20) NOT NULL UNIQUE,
        is_used BOOLEAN DEFAULT FALSE,
        used_by UUID REFERENCES users(id) ON DELETE SET NULL,
        used_at TIMESTAMPTZ,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 2. Add lifecycle management columns if missing
    await client.query(`
      ALTER TABLE verification_codes 
      ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS intended_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS is_revoked BOOLEAN DEFAULT FALSE,
      ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS revoked_by UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS batch_id UUID;
    `);

    // 3. Create indexes for efficient filtering and searching
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_vcode_code ON verification_codes(code);
      CREATE INDEX IF NOT EXISTS idx_vcode_revoked ON verification_codes(is_revoked);
      CREATE INDEX IF NOT EXISTS idx_vcode_used ON verification_codes(is_used);
      CREATE INDEX IF NOT EXISTS idx_vcode_created ON verification_codes(created_at);
      CREATE INDEX IF NOT EXISTS idx_vcode_batch ON verification_codes(batch_id);
    `);

    await client.query('COMMIT');
    console.log('[Migration] V12 Setup Codes schema verified and updated successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Migration] Failed to execute V12 Setup Codes migration:', error);
  } finally {
    client.release();
  }
}
