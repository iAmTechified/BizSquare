-- ==============================================================================
-- BIZSQUARE SCHEMA V11: SPOTLIGHT NOTIFICATION ENGINE, REMINDERS & BATCHING
-- ==============================================================================

-- 1. Spotlight Reminder Tracking Log (Section 2, 3, 5, 6)
CREATE TABLE IF NOT EXISTS spotlight_reminders_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES spotlight_campaigns(id) ON DELETE CASCADE,
    reminder_index INT NOT NULL DEFAULT 1,
    style_variant VARCHAR(30) NOT NULL, -- ALERT | RING | PROGRESS | SOCIAL | FINAL_CALL
    dedup_key VARCHAR(150) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SENT', -- SENT | CANCELLED | EXPIRED
    sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_srl_user_camp ON spotlight_reminders_log(user_id, campaign_id);

-- 2. Spotlight Participation Batching Queue (Section 8)
CREATE TABLE IF NOT EXISTS spotlight_participation_batch (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES spotlight_campaigns(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    actor_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    actor_name VARCHAR(150) NOT NULL,
    batch_window_start TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_spb_target_window ON spotlight_participation_batch(target_user_id, processed, batch_window_start);
