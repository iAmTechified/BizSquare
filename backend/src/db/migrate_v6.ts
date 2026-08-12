import fs from 'fs';
import path from 'path';
import { pool } from './pool';

async function runV6Migration() {
  console.log('Connecting to Neon PostgreSQL for Schema V6 Contacts & Labels Migration...');
  const client = await pool.connect();
  try {
    const sqlPath = path.join(process.cwd(), 'src', 'db', 'schema_v6_contacts.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('Executing Contacts & Labels V6 Migration SQL...');
    await client.query(sql);
    console.log('✅ Schema V6 Migration completed successfully!');

    const { rows: labelCount } = await client.query('SELECT COUNT(*) FROM contact_labels');
    console.log(`📊 Total Contact Labels in DB: ${labelCount[0].count}`);
  } catch (err) {
    console.error('❌ V6 Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runV6Migration();
