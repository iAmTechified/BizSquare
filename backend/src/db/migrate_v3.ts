import fs from 'fs';
import path from 'path';
import { pool } from './pool';

async function runV3Migration() {
  console.log('Connecting to Neon PostgreSQL for Schema V3 Migration...');
  const client = await pool.connect();
  try {
    const sqlPath = path.join(process.cwd(), 'src', 'db', 'schema_v3_interest_engine.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('Executing Interest & Demand + Content Engine V3 Migration SQL...');
    await client.query(sql);
    console.log('✅ Schema V3 Migration completed successfully!');

    // Verify entity counts
    const { rows: taxCount } = await client.query('SELECT COUNT(*) FROM interest_taxonomies');
    const { rows: relCount } = await client.query('SELECT COUNT(*) FROM interest_taxonomy_relationships');
    const { rows: contentCount } = await client.query('SELECT COUNT(*) FROM content_items');
    const { rows: optCount } = await client.query('SELECT COUNT(*) FROM content_options');
    const { rows: signalCount } = await client.query('SELECT COUNT(*) FROM content_signal_mappings');

    console.log(`📊 Total Interest Taxonomies: ${taxCount[0].count}`);
    console.log(`📊 Total Taxonomy Relationships: ${relCount[0].count}`);
    console.log(`📊 Total Active Content Items: ${contentCount[0].count}`);
    console.log(`📊 Total Content Options: ${optCount[0].count}`);
    console.log(`📊 Total Signal Mappings: ${signalCount[0].count}`);
  } catch (err) {
    console.error('❌ V3 Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runV3Migration();
