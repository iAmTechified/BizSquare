-- ==============================================================================
-- BIZSQUARE SCHEMA V10: UNIFIED NOTIFICATION FOUNDATION & PREFERENCES
-- ==============================================================================

-- 1. Unified User Notifications Table
CREATE TABLE IF NOT EXISTS user_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source VARCHAR(20) NOT NULL DEFAULT 'BACKEND', -- BACKEND | ADMIN | LOCAL
    event_type VARCHAR(80) NOT NULL, -- e.g. contact_gain.completed, spotlight.turn_started
    category VARCHAR(30) NOT NULL DEFAULT 'SYSTEM', -- CONTACT_GAIN | SPOTLIGHT | DAILY_PULSE | SYSTEM
    priority VARCHAR(20) NOT NULL DEFAULT 'INFORMATIONAL', -- ACTION_REQUIRED | IMPORTANT | INFORMATIONAL
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    visual_variant VARCHAR(30) DEFAULT 'DEFAULT', -- DEFAULT | HIGHLIGHT | ALERT | SUCCESS
    sound_variant VARCHAR(30) DEFAULT 'DEFAULT', -- DEFAULT | URGENT | CHIME
    action_url VARCHAR(500), -- Deep link URI e.g. bizsquare://contacts/square
    is_read BOOLEAN DEFAULT FALSE,
    opened_at TIMESTAMPTZ,
    data JSONB DEFAULT '{}'::jsonb,
    payload JSONB DEFAULT '{}'::jsonb,
    dedup_key VARCHAR(150),
    status VARCHAR(20) DEFAULT 'SENT', -- PENDING | SENT | DELIVERED | OPENED | DISMISSED | EXPIRED | SUPPRESSED | FAILED
    scheduled_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_notification_dedup UNIQUE (dedup_key)
);

CREATE INDEX IF NOT EXISTS idx_un_user_status ON user_notifications(user_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_un_dedup ON user_notifications(dedup_key);
CREATE INDEX IF NOT EXISTS idx_un_expires ON user_notifications(expires_at) WHERE expires_at IS NOT NULL;

-- 2. User Notification Preferences Table (Section 9)
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(30) NOT NULL, -- CONTACT_GAIN | SPOTLIGHT | DAILY_PULSE | SYSTEM
    enabled BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_category_pref UNIQUE (user_id, category)
);

CREATE INDEX IF NOT EXISTS idx_unp_user ON user_notification_preferences(user_id);

-- 3. Telemetry Analytics Table (Section 8)
CREATE TABLE IF NOT EXISTS notification_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    notification_id UUID,
    event_type VARCHAR(60) NOT NULL,
    -- Events: notification_created, notification_scheduled, notification_sent,
    -- notification_delivered, notification_opened, notification_dismissed,
    -- notification_deep_linked, notification_actioned, notification_expired,
    -- notification_suppressed, notification_failed
    source VARCHAR(20) DEFAULT 'BACKEND',
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_na_user_event ON notification_analytics(user_id, event_type, created_at);
