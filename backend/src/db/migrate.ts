import fs from 'fs';
import path from 'path';
import { pool } from './pool';

async function runMigration() {
  console.log('Connecting to Neon PostgreSQL database...');
  const client = await pool.connect();
  try {
    const sqlPath = path.join(process.cwd(), 'src', 'db', 'schema_v2_migration.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('Executing V2 Migration SQL...');
    await client.query(sql);
    console.log('✅ V2 Migration & Taxonomy Seeding completed successfully!');
    
    // Verify categories count
    const { rows: catRows } = await client.query('SELECT COUNT(*) FROM categories');
    const { rows: nicheRows } = await client.query('SELECT COUNT(*) FROM micro_niches');
    const { rows: vCodes } = await client.query('SELECT COUNT(*) FROM verification_codes');
    console.log(`📊 Total Categories: ${catRows[0].count}`);
    console.log(`📊 Total Micro-Niches: ${nicheRows[0].count}`);
    console.log(`📊 Total Verification Codes: ${vCodes[0].count}`);
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
