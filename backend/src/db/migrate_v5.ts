import fs from 'fs';
import path from 'path';
import { pool } from './pool';

async function runV5Migration() {
  console.log('Connecting to Neon PostgreSQL for Schema V5 Spotlight & Notifications Migration...');
  const client = await pool.connect();
  try {
    const sqlPath = path.join(process.cwd(), 'src', 'db', 'schema_v5_home_and_spotlight.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('Executing Spotlight & Notifications V5 Migration SQL...');
    await client.query(sql);
    console.log('✅ Schema V5 Migration completed successfully!');

    // Check tables
    const { rows: campCount } = await client.query('SELECT COUNT(*) FROM spotlight_campaigns');
    const { rows: partCount } = await client.query('SELECT COUNT(*) FROM spotlight_participations');
    const { rows: notifCount } = await client.query('SELECT COUNT(*) FROM user_notifications');

    console.log(`📊 Total Spotlight Campaigns: ${campCount[0].count}`);
    console.log(`📊 Total Spotlight Participations: ${partCount[0].count}`);
    console.log(`📊 Total User Notifications: ${notifCount[0].count}`);
  } catch (err) {
    console.error('❌ V5 Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runV5Migration();
