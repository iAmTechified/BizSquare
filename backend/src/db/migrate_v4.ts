import fs from 'fs';
import path from 'path';
import { pool } from './pool';

async function runV4Migration() {
  console.log('Connecting to Neon PostgreSQL for Schema V4 Matching Engine Migration...');
  const client = await pool.connect();
  try {
    const sqlPath = path.join(process.cwd(), 'src', 'db', 'schema_v4_matching_engine.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('Executing Matching Engine V4 Migration SQL...');
    await client.query(sql);
    console.log('✅ Schema V4 Migration completed successfully!');

    // Verify entity tables
    const { rows: cycleCount } = await client.query('SELECT COUNT(*) FROM weekly_matching_cycles');
    const { rows: allocCount } = await client.query('SELECT COUNT(*) FROM match_allocations');
    const { rows: relCount } = await client.query('SELECT COUNT(*) FROM contact_relationships');

    console.log(`📊 Total Weekly Matching Cycles: ${cycleCount[0].count}`);
    console.log(`📊 Total Match Allocations: ${allocCount[0].count}`);
    console.log(`📊 Total Contact Relationships: ${relCount[0].count}`);
  } catch (err) {
    console.error('❌ V4 Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runV4Migration();
