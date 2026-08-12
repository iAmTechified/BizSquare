import { pool } from './pool';
import * as fs from 'fs';
import * as path from 'path';

async function migrateV10() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema_v10_notification_foundation.sql'), 'utf-8');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('✅ Migration V10 (Unified Notification Foundation & Preferences) applied successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration V10 failed:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

migrateV10().catch(process.exit);
