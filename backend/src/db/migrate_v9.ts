import { pool } from './pool';
import * as fs from 'fs';
import * as path from 'path';

async function migrateV9() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema_v9_retention.sql'), 'utf-8');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('✅ Migration V9 (Retention, Interaction Memory & Concentration) applied successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration V9 failed:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

migrateV9().catch(process.exit);
