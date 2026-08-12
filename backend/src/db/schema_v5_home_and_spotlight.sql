-- ==============================================================================
-- BIZSQUARE SCHEMA V5: SPOTLIGHT SYSTEM & USER NOTIFICATIONS
-- ==============================================================================

-- 1. SPOTLIGHT CAMPAIGNS
CREATE TABLE IF NOT EXISTS spotlight_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL DEFAULT 'Featured Business Spotlight',
    promo_text TEXT NOT NULL,
    caption TEXT NOT NULL,
    flyer_url TEXT,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE NOT NULL DEFAULT CURRENT_DATE,
    target_participants INT DEFAULT 48,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sc_user ON spotlight_campaigns(user_id);
CREATE INDEX IF NOT EXISTS idx_sc_active ON spotlight_campaigns(is_active);
CREATE INDEX IF NOT EXISTS idx_sc_dates ON spotlight_campaigns(start_date, end_date);

-- 2. SPOTLIGHT PARTICIPATIONS (Who shared for whom)
CREATE TABLE IF NOT EXISTS spotlight_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES spotlight_campaigns(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel VARCHAR(40) DEFAULT 'whatsapp_status',
    verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_campaign_participation UNIQUE (campaign_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_sp_campaign ON spotlight_participations(campaign_id);
CREATE INDEX IF NOT EXISTS idx_sp_user ON spotlight_participations(user_id);

-- 3. USER NOTIFICATIONS
CREATE TABLE IF NOT EXISTS user_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(40) DEFAULT 'system', -- contact_gain, spotlight, match, system
    is_read BOOLEAN DEFAULT FALSE,
    action_url VARCHAR(100),
    data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_un_user ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_un_unread ON user_notifications(user_id, is_read);
