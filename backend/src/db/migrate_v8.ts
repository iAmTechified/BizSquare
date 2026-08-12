import { pool } from './pool';
import * as fs from 'fs';
import * as path from 'path';

async function migrateV8() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema_v8_push.sql'), 'utf-8');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('✅ Migration V8 (Push Notifications & Retention) applied successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration V8 failed:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

migrateV8().catch(process.exit);
