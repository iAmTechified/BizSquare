import { pool } from './pool';

export async function migrateV10AdminFoundation() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Ensure users table has access_level column
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS access_level VARCHAR(20) DEFAULT 'user';
    `);

    // 2. Create audit_logs table for administrative auditing
    await client.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        admin_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        action VARCHAR(100) NOT NULL,
        resource_type VARCHAR(100) NOT NULL,
        resource_id VARCHAR(255),
        metadata JSONB DEFAULT '{}',
        ip_address VARCHAR(45),
        user_agent TEXT,
        result VARCHAR(20) DEFAULT 'success',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create index on audit_logs for performance
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_user_id ON audit_logs(admin_user_id);
      CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
    `);

    // 3. Ensure default Super Admin account exists
    await client.query(`
      INSERT INTO users (phone_number, full_name, business_name, access_level, is_active, onboarding_completed, verification_status)
      VALUES ('+2348000000000', 'BizSquare System Admin', 'BizSquare Admin Headquarters', 'super_admin', TRUE, TRUE, 'verified')
      ON CONFLICT (phone_number) 
      DO UPDATE SET access_level = 'super_admin', is_active = TRUE, onboarding_completed = TRUE;
    `);

    await client.query(`
      INSERT INTO users (phone_number, full_name, business_name, access_level, is_active, onboarding_completed, verification_status)
      VALUES ('08000000000', 'BizSquare System Admin', 'BizSquare Admin Headquarters', 'super_admin', TRUE, TRUE, 'verified')
      ON CONFLICT (phone_number) 
      DO UPDATE SET access_level = 'super_admin', is_active = TRUE, onboarding_completed = TRUE;
    `);

    await client.query('COMMIT');
    console.log('Migration v10 (Admin Foundation, Audit Logs & Super Admin Seeding) completed successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Migration v10 failed:', error);
    throw error;
  } finally {
    client.release();
  }
}
