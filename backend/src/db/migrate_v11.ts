import { pool } from './pool';
import * as fs from 'fs';
import * as path from 'path';

async function migrateV11() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema_v11_spotlight_notifications.sql'), 'utf-8');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('✅ Migration V11 (Spotlight Notifications & Batching) applied successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration V11 failed:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

migrateV11().catch(process.exit);
