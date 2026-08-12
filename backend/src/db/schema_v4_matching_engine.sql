-- ==============================================================================
-- BIZSQUARE SCHEMA V4: MATCHING ENGINE & CONTACT GAIN ARCHITECTURE
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. WEEKLY MATCHING CYCLES
CREATE TABLE IF NOT EXISTS weekly_matching_cycles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cycle_number SERIAL,
    batch_date DATE NOT NULL DEFAULT CURRENT_DATE,
    network_size INT DEFAULT 0,
    target_per_user INT DEFAULT 0,
    allocation_percentage NUMERIC(4,2) DEFAULT 0.10,
    status VARCHAR(30) DEFAULT 'INITIATED', -- INITIATED, RUNNING, COMPLETED, FAILED
    users_processed INT DEFAULT 0,
    users_filled INT DEFAULT 0,
    users_underfilled INT DEFAULT 0,
    total_allocations INT DEFAULT 0,
    tier_1_count INT DEFAULT 0,
    tier_2_count INT DEFAULT 0,
    tier_3_count INT DEFAULT 0,
    competitor_exclusions_count INT DEFAULT 0,
    execution_duration_ms INT DEFAULT 0,
    error_log TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_wmc_date ON weekly_matching_cycles(batch_date);
CREATE INDEX IF NOT EXISTS idx_wmc_status ON weekly_matching_cycles(status);

-- 2. MATCH ALLOCATIONS (Deterministic cycle allocations)
CREATE TABLE IF NOT EXISTS match_allocations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cycle_id UUID NOT NULL REFERENCES weekly_matching_cycles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    candidate_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tier VARCHAR(20) NOT NULL, -- TIER_1, TIER_2, TIER_3
    final_score NUMERIC(7,3) NOT NULL,
    allocation_position INT NOT NULL,
    match_reason VARCHAR(60) NOT NULL, -- PRIMARY_SUPPLY_MATCH, SECONDARY_SUPPLY_MATCH, FALLBACK_COMPLEMENTARY, FALLBACK_ADJACENT, FALLBACK_DIVERSE, FALLBACK_NETWORK_EXPANSION
    matched_interest_id UUID,
    matched_interest_slug VARCHAR(100),
    matched_interest_weight NUMERIC(5,4),
    matched_supply_id UUID,
    matched_supply_type VARCHAR(20) DEFAULT 'primary', -- primary, secondary, fallback
    is_mutual BOOLEAN DEFAULT FALSE,
    status VARCHAR(30) DEFAULT 'ALLOCATED', -- ALLOCATED, SYNC_PENDING, SYNCED, REJECTED
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cycle_user_candidate UNIQUE (cycle_id, user_id, candidate_user_id)
);

CREATE INDEX IF NOT EXISTS idx_ma_cycle ON match_allocations(cycle_id);
CREATE INDEX IF NOT EXISTS idx_ma_user ON match_allocations(user_id);
CREATE INDEX IF NOT EXISTS idx_ma_candidate ON match_allocations(candidate_user_id);
CREATE INDEX IF NOT EXISTS idx_ma_tier ON match_allocations(tier);

-- 3. MATCH HISTORY (Audit & Explainability Log)
CREATE TABLE IF NOT EXISTS match_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cycle_id UUID REFERENCES weekly_matching_cycles(id) ON DELETE SET NULL,
    user_a UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tier VARCHAR(20) NOT NULL,
    score NUMERIC(7,3) NOT NULL,
    match_reason VARCHAR(60) NOT NULL,
    interest_used VARCHAR(100),
    interest_weight NUMERIC(5,4),
    supply_used VARCHAR(100),
    supply_type VARCHAR(20),
    candidate_primary_offer VARCHAR(100),
    candidate_secondary_offers TEXT[] DEFAULT '{}',
    mutual_match BOOLEAN DEFAULT FALSE,
    allocation_position INT,
    explanation_text TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mh_user_a ON match_history(user_a);
CREATE INDEX IF NOT EXISTS idx_mh_user_b ON match_history(user_b);
CREATE INDEX IF NOT EXISTS idx_mh_cycle ON match_history(cycle_id);

-- 4. CONTACT RELATIONSHIPS (Reciprocal Contact Ledger)
CREATE TABLE IF NOT EXISTS contact_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source VARCHAR(30) DEFAULT 'AUTOMATIC_MATCH', -- AUTOMATIC_MATCH, MANUAL_CONTACT, DISCOVERY
    match_id UUID REFERENCES match_allocations(id) ON DELETE SET NULL,
    cycle_id UUID REFERENCES weekly_matching_cycles(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, MUTED, REMOVED, BLOCKED
    sync_status VARCHAR(20) DEFAULT 'PENDING_SYNC', -- PENDING_SYNC, SYNCED, FAILED
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_contact_pair UNIQUE (user_a_id, user_b_id),
    CONSTRAINT chk_no_self_contact CHECK (user_a_id <> user_b_id)
);

CREATE INDEX IF NOT EXISTS idx_cr_user_a ON contact_relationships(user_a_id);
CREATE INDEX IF NOT EXISTS idx_cr_user_b ON contact_relationships(user_b_id);
CREATE INDEX IF NOT EXISTS idx_cr_sync ON contact_relationships(sync_status);

-- 5. CYCLE ALLOCATION SUMMARIES (User-level cycle results)
CREATE TABLE IF NOT EXISTS cycle_allocation_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cycle_id UUID NOT NULL REFERENCES weekly_matching_cycles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_count INT NOT NULL,
    allocated_count INT NOT NULL,
    tier_1_allocated INT DEFAULT 0,
    tier_2_allocated INT DEFAULT 0,
    tier_3_allocated INT DEFAULT 0,
    allocation_status VARCHAR(30) NOT NULL, -- FILLED, PARTIALLY_FILLED, UNDERFILLED, NO_ELIGIBLE_SUPPLY
    underfill_reason VARCHAR(60), -- INSUFFICIENT_ELIGIBLE_SUPPLY, COMPETITOR_COLLISION_RESTRICTION, ALL_CANDIDATES_CONNECTED
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cycle_user_summary UNIQUE (cycle_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_cas_cycle ON cycle_allocation_summaries(cycle_id);
CREATE INDEX IF NOT EXISTS idx_cas_user ON cycle_allocation_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_cas_status ON cycle_allocation_summaries(allocation_status);
