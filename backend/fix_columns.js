const { Pool } = require('pg');
require('dotenv').config();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function fixTables() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Fix user_notifications — add ALL missing V10 columns
    await client.query(`
      ALTER TABLE user_notifications
      ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'BACKEND',
      ADD COLUMN IF NOT EXISTS event_type VARCHAR(80) NOT NULL DEFAULT 'system.announcement',
      ADD COLUMN IF NOT EXISTS category VARCHAR(30) NOT NULL DEFAULT 'SYSTEM',
      ADD COLUMN IF NOT EXISTS visual_variant VARCHAR(30) DEFAULT 'DEFAULT',
      ADD COLUMN IF NOT EXISTS sound_variant VARCHAR(30) DEFAULT 'DEFAULT',
      ADD COLUMN IF NOT EXISTS payload JSONB DEFAULT '{}'::jsonb;
    `);
    console.log('✅ user_notifications columns fixed');

    // Fix notification_analytics — add missing source column
    await client.query(`
      ALTER TABLE notification_analytics
      ADD COLUMN IF NOT EXISTS source VARCHAR(20) DEFAULT 'BACKEND';
    `);
    console.log('✅ notification_analytics columns fixed');

    await client.query('COMMIT');
    console.log('✅ All schema fixes applied successfully');

    // Verify
    const { rows: unCols } = await client.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'user_notifications' ORDER BY ordinal_position`);
    console.log('user_notifications columns:', unCols.map(r => r.column_name).join(', '));

    const { rows: naCols } = await client.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'notification_analytics' ORDER BY ordinal_position`);
    console.log('notification_analytics columns:', naCols.map(r => r.column_name).join(', '));

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Failed:', err.message);
  } finally {
    client.release();
    pool.end();
  }
}

fixTables();
