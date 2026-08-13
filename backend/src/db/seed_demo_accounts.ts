import { pool } from './pool';
import bcrypt from 'bcryptjs';
import fs from 'fs';
import path from 'path';

async function seedDemoAccounts() {
  const client = await pool.connect();
  try {
    console.log('🌱 Applying schema_v12_slug_niches.sql migration...');
    const sqlPath = path.join(process.cwd(), 'src', 'db', 'schema_v12_slug_niches.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    await client.query(sql);
    console.log('✅ Schema V12 (Categories & Micro-Niches) applied!');

    await client.query('BEGIN');

    console.log('🌱 Seeding BizSquare Demo Accounts into PostgreSQL...');

    const pinHash = await bcrypt.hash('1234', 10);

    // 1. Seed Demo Merchant 1: Adebayo Electronics (08012345678 & +2348012345678)
    const res1 = await client.query(`
      INSERT INTO users (
        phone_number, full_name, business_name, username, pin_hash, 
        avatar_id, is_active, onboarding_completed, verification_status, access_level
      )
      VALUES (
        '08012345678', 'Adebayo Johnson', 'Adebayo Electronics', 'adebayo_store', $1, 
        1, TRUE, TRUE, 'verified', 'merchant'
      )
      ON CONFLICT (phone_number) DO UPDATE SET 
        pin_hash = $1, 
        business_name = 'Adebayo Electronics',
        username = 'adebayo_store',
        onboarding_completed = TRUE, 
        verification_status = 'verified'
      RETURNING id;
    `, [pinHash]);

    const user1Id = res1.rows[0].id;

    // Also seed international format +2348012345678
    await client.query(`
      INSERT INTO users (
        phone_number, full_name, business_name, username, pin_hash, 
        avatar_id, is_active, onboarding_completed, verification_status, access_level
      )
      VALUES (
        '+2348012345678', 'Adebayo Johnson', 'Adebayo Electronics', 'adebayo_store_int', $1, 
        1, TRUE, TRUE, 'verified', 'merchant'
      )
      ON CONFLICT (phone_number) DO UPDATE SET 
        pin_hash = $1, 
        business_name = 'Adebayo Electronics',
        onboarding_completed = TRUE, 
        verification_status = 'verified';
    `, [pinHash]);

    // Add supply niches for Adebayo
    await client.query(`
      INSERT INTO business_micro_niches (user_id, micro_niche_id, is_primary)
      VALUES 
        ($1, 'mn_smartphones_laptops', TRUE),
        ($1, 'mn_tech_accessories', FALSE),
        ($1, 'mn_consumer_electronics', FALSE)
      ON CONFLICT (user_id, micro_niche_id) DO NOTHING;
    `, [user1Id]);

    // Add buy demand interests for Adebayo
    await client.query(`
      INSERT INTO baseline_demand (user_id, micro_niche_id, source, is_active)
      VALUES 
        ($1, 'mn_mens_clothing', 'onboarding', TRUE),
        ($1, 'mn_fabrics_textiles', 'onboarding', TRUE)
      ON CONFLICT (user_id, micro_niche_id) DO UPDATE SET is_active = TRUE;
    `, [user1Id]);

    // 2. Seed Demo Merchant 2: Kemi Fashion & Boutique (08098765432 & +2348098765432)
    const res2 = await client.query(`
      INSERT INTO users (
        phone_number, full_name, business_name, username, pin_hash, 
        avatar_id, is_active, onboarding_completed, verification_status, access_level
      )
      VALUES (
        '08098765432', 'Kemi Adebisi', 'Kemi Fashion & Boutique', 'kemi_boutique', $1, 
        3, TRUE, TRUE, 'verified', 'merchant'
      )
      ON CONFLICT (phone_number) DO UPDATE SET 
        pin_hash = $1, 
        business_name = 'Kemi Fashion & Boutique',
        username = 'kemi_boutique',
        onboarding_completed = TRUE, 
        verification_status = 'verified'
      RETURNING id;
    `, [pinHash]);

    const user2Id = res2.rows[0].id;

    await client.query(`
      INSERT INTO users (
        phone_number, full_name, business_name, username, pin_hash, 
        avatar_id, is_active, onboarding_completed, verification_status, access_level
      )
      VALUES (
        '+2348098765432', 'Kemi Adebisi', 'Kemi Fashion & Boutique', 'kemi_boutique_int', $1, 
        3, TRUE, TRUE, 'verified', 'merchant'
      )
      ON CONFLICT (phone_number) DO UPDATE SET 
        pin_hash = $1, 
        business_name = 'Kemi Fashion & Boutique',
        onboarding_completed = TRUE, 
        verification_status = 'verified';
    `, [pinHash]);

    await client.query(`
      INSERT INTO business_micro_niches (user_id, micro_niche_id, is_primary)
      VALUES 
        ($1, 'mn_mens_clothing', TRUE),
        ($1, 'mn_bags_accessories', FALSE),
        ($1, 'mn_fabrics_textiles', FALSE)
      ON CONFLICT (user_id, micro_niche_id) DO NOTHING;
    `, [user2Id]);

    await client.query(`
      INSERT INTO baseline_demand (user_id, micro_niche_id, source, is_active)
      VALUES 
        ($1, 'mn_smartphones_laptops', 'onboarding', TRUE),
        ($1, 'mn_skincare', 'onboarding', TRUE)
      ON CONFLICT (user_id, micro_niche_id) DO UPDATE SET is_active = TRUE;
    `, [user2Id]);

    // 3. Seed Super Admin Account (08000000000 & +2348000000000)
    await client.query(`
      INSERT INTO users (
        phone_number, full_name, business_name, username, pin_hash, 
        avatar_id, is_active, onboarding_completed, verification_status, access_level
      )
      VALUES (
        '08000000000', 'BizSquare System Admin', 'BizSquare Admin Headquarters', 'bizsquare_admin', $1, 
        1, TRUE, TRUE, 'verified', 'super_admin'
      )
      ON CONFLICT (phone_number) DO UPDATE SET 
        pin_hash = $1,
        access_level = 'super_admin',
        is_active = TRUE, 
        onboarding_completed = TRUE,
        verification_status = 'verified';
    `, [pinHash]);

    await client.query(`
      INSERT INTO users (
        phone_number, full_name, business_name, username, pin_hash, 
        avatar_id, is_active, onboarding_completed, verification_status, access_level
      )
      VALUES (
        '+2348000000000', 'BizSquare System Admin', 'BizSquare Admin Headquarters', 'bizsquare_admin_int', $1, 
        1, TRUE, TRUE, 'verified', 'super_admin'
      )
      ON CONFLICT (phone_number) DO UPDATE SET 
        pin_hash = $1,
        access_level = 'super_admin',
        is_active = TRUE, 
        onboarding_completed = TRUE,
        verification_status = 'verified';
    `, [pinHash]);

    await client.query('COMMIT');
    console.log('✅ Demo accounts seeded successfully!');
    console.log('--------------------------------------------------');
    console.log('📱 Merchant Account 1:');
    console.log('   Phone: 08012345678');
    console.log('   PIN: 1234');
    console.log('   Business: Adebayo Electronics');
    console.log('--------------------------------------------------');
    console.log('📱 Merchant Account 2:');
    console.log('   Phone: 08098765432');
    console.log('   PIN: 1234');
    console.log('   Business: Kemi Fashion & Boutique');
    console.log('--------------------------------------------------');
    console.log('👑 Admin Account:');
    console.log('   Phone: 08000000000');
    console.log('   PIN: 1234');
    console.log('   Business: BizSquare Admin HQ');
    console.log('--------------------------------------------------');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error seeding demo accounts:', error);
    process.exit(1);
  } finally {
    client.release();
    process.exit(0);
  }
}

seedDemoAccounts();
