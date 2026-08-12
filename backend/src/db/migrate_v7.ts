import fs from 'fs';
import path from 'path';
import { pool } from './pool';

async function runMigration() {
  console.log('Connecting to Neon PostgreSQL database for V7 Spotlight migration...');
  const client = await pool.connect();
  try {
    const sqlPath = path.join(process.cwd(), 'src', 'db', 'schema_v7_spotlight.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('Executing V7 Spotlight Migration SQL...');
    await client.query(sql);
    console.log('✅ V7 Spotlight Migration applied successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
