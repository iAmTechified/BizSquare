-- Core Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. NICHES: Defines the categories of supply and demand
CREATE TABLE niches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. USERS: Core identity and points ledger
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    niche_id UUID REFERENCES niches(id) ON DELETE RESTRICT,
    akawo_points INT DEFAULT 10 CHECK (akawo_points >= 0),
    access_level VARCHAR(20) DEFAULT 'user', -- 'user', 'business_owner', 'moderator', 'admin', 'super_admin'
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. MATCHES: The immutable historical record of who received whose contact card
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    batch_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'synced', -- 'synced', 'ghosted', 'revoked'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_match_pair UNIQUE (user_a_id, user_b_id),
    CONSTRAINT no_self_match CHECK (user_a_id <> user_b_id)
);

-- CRITICAL INDEXES for Matchmaking Query Performance
CREATE INDEX idx_matches_user_a ON matches(user_a_id);
CREATE INDEX idx_matches_user_b ON matches(user_b_id);
CREATE INDEX idx_matches_batch_date ON matches(batch_date);

-- 4. SCENARIO POLLS: The Tinder-style cards for business scenarios
CREATE TABLE scenario_polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    target_niche_id UUID REFERENCES niches(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. USER POLL RESPONSES: Maps real-time intent
CREATE TABLE user_poll_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    poll_id UUID REFERENCES scenario_polls(id) ON DELETE CASCADE,
    response BOOLEAN NOT NULL, -- TRUE = Swipe Right, FALSE = Swipe Left
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_poll UNIQUE (user_id, poll_id)
);

-- 6. AKAWO LEDGER: Immutable record of points earned/spent
CREATE TABLE akawo_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    points_awarded INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- 'status_mention', 'penalty', 'reward'
    verified_by_bot BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Trigger to automatically update the users.akawo_points balance
CREATE OR REPLACE FUNCTION update_akawo_balance() RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET akawo_points = akawo_points + NEW.points_awarded 
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_akawo_balance
AFTER INSERT ON akawo_ledger
FOR EACH ROW EXECUTE FUNCTION update_akawo_balance();

-- 8. POCKET CRM (USER CONTACTS)
CREATE TABLE user_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    external_name VARCHAR(100),
    external_phone VARCHAR(20),
    label VARCHAR(50) DEFAULT 'lead', -- 'lead', 'customer', 'vendor'
    lead_grade VARCHAR(1) DEFAULT 'C', -- 'A', 'B', 'C', 'D', 'F'
    relationship_strength INT DEFAULT 0 CHECK (relationship_strength >= 0 AND relationship_strength <= 100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_contact UNIQUE (owner_id, contact_user_id),
    CONSTRAINT require_contact_info CHECK (contact_user_id IS NOT NULL OR (external_name IS NOT NULL AND external_phone IS NOT NULL))
);
