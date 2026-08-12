-- ==============================================================================
-- BIZSQUARE SCHEMA V9: RETENTION, INTERACTION MEMORY & CONCENTRATION
-- ==============================================================================

-- 1. Retention & Telemetry Analytics Events (Section 19)
CREATE TABLE IF NOT EXISTS retention_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(60) NOT NULL,
    -- Allowed event types:
    -- daily_wall_opened, daily_wall_interaction, daily_wall_completed, daily_wall_skipped,
    -- interest_signal_created, interest_signal_strengthened, interest_signal_decayed,
    -- contact_gain_ready, contact_gain_viewed, square_contact_opened, square_contact_actioned,
    -- spotlight_opened, spotlight_completed, widget_opened, push_opened
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ra_user_event ON retention_analytics(user_id, event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_ra_event_type ON retention_analytics(event_type, created_at);

-- 2. Interactive Wall Memory (Section 7)
-- Stores detailed memory of content shown, answered, skipped, and inferred confidence
CREATE TABLE IF NOT EXISTS user_wall_memory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id VARCHAR(100) NOT NULL,
    interaction_type VARCHAR(30) NOT NULL, -- swipe | tap | choose | react | rank | this_or_that | slider | quick_response
    response_value JSONB NOT NULL DEFAULT '{}'::jsonb,
    confidence_score NUMERIC(4,3) DEFAULT 0.500, -- 0.000 to 1.000 confidence of inferred interest
    skipped BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_card_memory UNIQUE (user_id, card_id)
);

CREATE INDEX IF NOT EXISTS idx_uwm_user ON user_wall_memory(user_id, created_at DESC);

-- 3. Demand Concentration Profile Cache (Section 9)
-- Pre-calculates Primary, Secondary, Emerging, and Weak interest tiers for matching
CREATE TABLE IF NOT EXISTS user_demand_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    primary_interests JSONB DEFAULT '[]'::jsonb,   -- Top active high-confidence interests
    secondary_interests JSONB DEFAULT '[]'::jsonb, -- Supporting active interests
    emerging_interests JSONB DEFAULT '[]'::jsonb,  -- Newly introduced or swiped interests
    background_interests JSONB DEFAULT '[]'::jsonb, -- Low-strength or dormant interests
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_demand_profile UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_udp_user ON user_demand_profiles(user_id);
