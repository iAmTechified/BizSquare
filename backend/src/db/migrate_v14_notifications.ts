import { pool } from './pool';

export async function migrateV14Notifications(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 0. Ensure push_tokens table, push_delivery_log, notification_analytics exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS push_tokens (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token TEXT NOT NULL,
          platform VARCHAR(10) NOT NULL DEFAULT 'android',
          registered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          is_active BOOLEAN DEFAULT TRUE,
          CONSTRAINT uq_push_token UNIQUE (token)
      );

      CREATE INDEX IF NOT EXISTS idx_pt_user ON push_tokens(user_id, is_active);

      CREATE TABLE IF NOT EXISTS push_delivery_log (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          notification_id UUID NOT NULL REFERENCES user_notifications(id) ON DELETE CASCADE,
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token TEXT,
          status VARCHAR(20) NOT NULL DEFAULT 'pending',
          sent_at TIMESTAMPTZ,
          opened_at TIMESTAMPTZ,
          failure_reason TEXT,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS notification_analytics (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID REFERENCES users(id) ON DELETE SET NULL,
          notification_id UUID REFERENCES user_notifications(id) ON DELETE SET NULL,
          event_type VARCHAR(50) NOT NULL,
          metadata JSONB DEFAULT '{}'::jsonb,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 1. Ensure user_notifications has all necessary columns (expires_at, dedup_key, priority, campaign_id, etc.)
    await client.query(`
      ALTER TABLE user_notifications
      ADD COLUMN IF NOT EXISTS dedup_key VARCHAR(150),
      ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'INFORMATIONAL',
      ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS opened_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS campaign_id UUID,
      ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS audience_type VARCHAR(50) DEFAULT 'ALL',
      ADD COLUMN IF NOT EXISTS push_sent BOOLEAN DEFAULT FALSE;
    `);

    // 2. Create notification_templates table for reusable templates
    await client.query(`
      CREATE TABLE IF NOT EXISTS notification_templates (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(150) NOT NULL,
        category VARCHAR(40) NOT NULL DEFAULT 'ANNOUNCEMENT',
        visual_variant VARCHAR(40) DEFAULT 'DEFAULT',
        sound_variant VARCHAR(40) DEFAULT 'DEFAULT',
        default_title VARCHAR(255) NOT NULL,
        default_body TEXT NOT NULL,
        default_cta VARCHAR(100) DEFAULT 'Open App',
        default_destination VARCHAR(255) DEFAULT 'bizsquare://home',
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 3. Seed initial approved templates if empty
    const { rows: tRows } = await client.query('SELECT COUNT(*) FROM notification_templates');
    if (parseInt(tRows[0].count, 10) === 0) {
      await client.query(`
        INSERT INTO notification_templates (name, category, visual_variant, sound_variant, default_title, default_body, default_cta, default_destination)
        VALUES 
          ('Weekly Network Announcement', 'ANNOUNCEMENT', 'HIGHLIGHT', 'DEFAULT', 'BizSquare Weekly Update', 'Hi {{firstName}}, check out your new business connections and status updates this week!', 'View Contacts', 'bizsquare://contacts/square'),
          ('Featured Spotlight Alert', 'SPOTLIGHT', 'GOLD', 'CHIME', 'Spotlight Showcase Live', 'Hi {{firstName}}, this week''s featured business spotlight is now active across the network!', 'View Spotlight', 'bizsquare://spotlight'),
          ('Contact Gain Discovery', 'CONTACT_GAIN', 'SUCCESS', 'DEFAULT', 'New Contacts Added', 'Congratulations {{firstName}}! You have gained {{newContactCount}} new verified contacts in your network.', 'View Square Contacts', 'bizsquare://contacts/square'),
          ('Important System Maintenance', 'IMPORTANT', 'ALERT', 'URGENT', 'Important System Update', 'Please complete your BizSquare profile setup to unlock full networking benefits.', 'Complete Setup', 'bizsquare://profile');
      `);
    }

    await client.query('COMMIT');
    console.log('[Migration] V14 Notifications & Push Tokens executed successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[Migration] Failed to execute V14 Notifications migration:', error);
  } finally {
    client.release();
  }
}


if (require.main === module) { migrateV14Notifications().then(() => process.exit(0)); }
