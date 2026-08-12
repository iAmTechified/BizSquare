-- ==============================================================================
-- BIZSQUARE SCHEMA V8: PUSH NOTIFICATIONS & RETENTION
-- ==============================================================================

-- 1. FCM Push Tokens (one row per device per user)
CREATE TABLE IF NOT EXISTS push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(10) NOT NULL DEFAULT 'android', -- 'android' | 'ios'
    registered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT uq_push_token UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_pt_user ON push_tokens(user_id, is_active);

-- 2. Push Delivery Log (one row per push send attempt)
CREATE TABLE IF NOT EXISTS push_delivery_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES user_notifications(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending | sent | delivered | failed | expired
    sent_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    failure_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pdl_notif ON push_delivery_log(notification_id);
CREATE INDEX IF NOT EXISTS idx_pdl_user ON push_delivery_log(user_id);

-- 3. Add deduplication key and priority to user_notifications
ALTER TABLE user_notifications
    ADD COLUMN IF NOT EXISTS dedup_key VARCHAR(150),
    ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'INFORMATIONAL', -- ACTION_REQUIRED | IMPORTANT_UPDATE | INFORMATIONAL
    ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS opened_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS push_sent BOOLEAN DEFAULT FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS idx_un_dedup ON user_notifications(dedup_key)
    WHERE dedup_key IS NOT NULL;

-- 4. Notification analytics events
CREATE TABLE IF NOT EXISTS notification_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    notification_id UUID REFERENCES user_notifications(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- notification_created | notification_sent | notification_opened | notification_dismissed | contact_gain_opened | spotlight_notification_opened
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_na_user ON notification_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_na_event ON notification_analytics(event_type, created_at);
