-- ============================================================
-- BizSquare Unified Schema V2 + Seeding
-- Designed for PostgreSQL 13+ & Neon Database
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS: Core identity, business identity, and points ledger
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    business_name VARCHAR(150),
    username VARCHAR(50) UNIQUE,
    avatar_id INT DEFAULT 1,
    pin_hash VARCHAR(255),
    akawo_points INT DEFAULT 10 CHECK (akawo_points >= 0),
    access_level VARCHAR(20) DEFAULT 'user', -- 'user', 'business_owner', 'moderator', 'admin'
    is_active BOOLEAN DEFAULT TRUE,
    onboarding_completed BOOLEAN DEFAULT FALSE,
    verification_status VARCHAR(20) DEFAULT 'unverified',
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- 2. CATEGORIES (broad groupings, NOT used for collision)
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. MICRO-NICHES (collision key, matched by engine)
CREATE TABLE IF NOT EXISTS micro_niches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(category_id, name)
);

CREATE INDEX IF NOT EXISTS idx_micro_niches_category ON micro_niches(category_id);

-- 4. BUSINESS_MICRO_NICHES junction (up to 3 per user, exactly 1 primary)
CREATE TABLE IF NOT EXISTS business_micro_niches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    micro_niche_id UUID NOT NULL REFERENCES micro_niches(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, micro_niche_id)
);

CREATE INDEX IF NOT EXISTS idx_bmn_user ON business_micro_niches(user_id);
CREATE INDEX IF NOT EXISTS idx_bmn_niche ON business_micro_niches(micro_niche_id);

-- 5. BASELINE DEMAND (Step 5 onboarding interests, up to 5)
CREATE TABLE IF NOT EXISTS baseline_demand (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    micro_niche_id UUID NOT NULL REFERENCES micro_niches(id) ON DELETE CASCADE,
    source VARCHAR(20) DEFAULT 'onboarding',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, micro_niche_id)
);

CREATE INDEX IF NOT EXISTS idx_baseline_user ON baseline_demand(user_id);

-- 6. DYNAMIC DEMAND (Daily Wall interactions, ~14-day decay)
CREATE TABLE IF NOT EXISTS dynamic_demand (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    micro_niche_id UUID NOT NULL REFERENCES micro_niches(id) ON DELETE CASCADE,
    source VARCHAR(30) DEFAULT 'daily_wall',
    interaction_type VARCHAR(20) NOT NULL, -- 'positive', 'negative', 'skip'
    strength FLOAT DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '14 days')
);

CREATE INDEX IF NOT EXISTS idx_dynamic_user ON dynamic_demand(user_id);
CREATE INDEX IF NOT EXISTS idx_dynamic_expires ON dynamic_demand(expires_at);

-- 7. VERIFICATION CODES (admin-generated, WhatsApp-delivered)
CREATE TABLE IF NOT EXISTS verification_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) NOT NULL UNIQUE,
    is_used BOOLEAN DEFAULT FALSE,
    used_by UUID REFERENCES users(id) ON DELETE SET NULL,
    used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vcode_code ON verification_codes(code);

-- 8. MATCHES: Historical contact exchange record
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    batch_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'synced',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_match_pair UNIQUE (user_a_id, user_b_id),
    CONSTRAINT no_self_match CHECK (user_a_id <> user_b_id)
);

CREATE INDEX IF NOT EXISTS idx_matches_user_a ON matches(user_a_id);
CREATE INDEX IF NOT EXISTS idx_matches_user_b ON matches(user_b_id);
CREATE INDEX IF NOT EXISTS idx_matches_batch_date ON matches(batch_date);

-- 9. AKAWO LEDGER
CREATE TABLE IF NOT EXISTS akawo_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    points_awarded INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    verified_by_bot BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION update_akawo_balance() RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET akawo_points = akawo_points + NEW.points_awarded 
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_akawo_balance ON akawo_ledger;
CREATE TRIGGER trigger_update_akawo_balance
AFTER INSERT ON akawo_ledger
FOR EACH ROW EXECUTE FUNCTION update_akawo_balance();

-- 10. SCENARIO POLLS (for Daily Interactive Wall)
CREATE TABLE IF NOT EXISTS scenario_polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    micro_niche_id UUID REFERENCES micro_niches(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 11. USER POLL RESPONSES
CREATE TABLE IF NOT EXISTS user_poll_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    poll_id UUID REFERENCES scenario_polls(id) ON DELETE CASCADE,
    response BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_poll UNIQUE (user_id, poll_id)
);

-- 12. POCKET CRM
CREATE TABLE IF NOT EXISTS user_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    external_name VARCHAR(100),
    external_phone VARCHAR(20),
    label VARCHAR(50) DEFAULT 'lead',
    lead_grade VARCHAR(1) DEFAULT 'C',
    relationship_strength INT DEFAULT 0 CHECK (relationship_strength >= 0 AND relationship_strength <= 100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_contact UNIQUE (owner_id, contact_user_id),
    CONSTRAINT require_contact_info CHECK (contact_user_id IS NOT NULL OR (external_name IS NOT NULL AND external_phone IS NOT NULL))
);

-- ============================================================
-- SEED TAXONOMY DATA
-- ============================================================

INSERT INTO categories (name, icon, sort_order) VALUES
('Fashion & Apparel', 'shopping_bag', 1),
('Food & Beverage', 'restaurant', 2),
('Tech & Gadgets', 'devices', 3),
('Beauty & Personal Care', 'spa', 4),
('Health & Wellness', 'health_and_safety', 5),
('Home & Living', 'home', 6),
('Logistics & Transport', 'local_shipping', 7),
('Professional Services', 'business_center', 8),
('Agriculture & Raw Materials', 'eco', 9),
('Education & Training', 'school', 10),
('Media & Entertainment', 'movie', 11),
('Construction & Real Estate', 'domain', 12)
ON CONFLICT (name) DO NOTHING;

-- Micro-Niches per Category
-- Fashion & Apparel
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Fashion & Apparel'), 'Footwear'),
((SELECT id FROM categories WHERE name='Fashion & Apparel'), 'Jewelry & Watches'),
((SELECT id FROM categories WHERE name='Fashion & Apparel'), 'Men''s Clothing'),
((SELECT id FROM categories WHERE name='Fashion & Apparel'), 'Women''s Clothing'),
((SELECT id FROM categories WHERE name='Fashion & Apparel'), 'Bags & Accessories'),
((SELECT id FROM categories WHERE name='Fashion & Apparel'), 'Children''s Clothing'),
((SELECT id FROM categories WHERE name='Fashion & Apparel'), 'Fabrics & Textiles')
ON CONFLICT (category_id, name) DO NOTHING;

-- Food & Beverage
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Food & Beverage'), 'Packaged Foods & Snacks'),
((SELECT id FROM categories WHERE name='Food & Beverage'), 'Beverages & Drinks'),
((SELECT id FROM categories WHERE name='Food & Beverage'), 'Catering & Event Food'),
((SELECT id FROM categories WHERE name='Food & Beverage'), 'Bakery & Confectionery'),
((SELECT id FROM categories WHERE name='Food & Beverage'), 'Fresh Produce & Groceries'),
((SELECT id FROM categories WHERE name='Food & Beverage'), 'Restaurant & Fast Food')
ON CONFLICT (category_id, name) DO NOTHING;

-- Tech & Gadgets
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Tech & Gadgets'), 'Smartphones & Laptops'),
((SELECT id FROM categories WHERE name='Tech & Gadgets'), 'Tech Accessories'),
((SELECT id FROM categories WHERE name='Tech & Gadgets'), 'Device Repairs'),
((SELECT id FROM categories WHERE name='Tech & Gadgets'), 'Software & SaaS'),
((SELECT id FROM categories WHERE name='Tech & Gadgets'), 'Consumer Electronics'),
((SELECT id FROM categories WHERE name='Tech & Gadgets'), 'Networking & Security')
ON CONFLICT (category_id, name) DO NOTHING;

-- Beauty & Personal Care
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Beauty & Personal Care'), 'Skincare Products'),
((SELECT id FROM categories WHERE name='Beauty & Personal Care'), 'Hair Care & Wigs'),
((SELECT id FROM categories WHERE name='Beauty & Personal Care'), 'Makeup & Cosmetics'),
((SELECT id FROM categories WHERE name='Beauty & Personal Care'), 'Perfumes & Fragrances'),
((SELECT id FROM categories WHERE name='Beauty & Personal Care'), 'Salon & Spa Services')
ON CONFLICT (category_id, name) DO NOTHING;

-- Health & Wellness
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Health & Wellness'), 'Pharmacy & Medicine'),
((SELECT id FROM categories WHERE name='Health & Wellness'), 'Fitness & Gym'),
((SELECT id FROM categories WHERE name='Health & Wellness'), 'Herbal & Natural Remedies'),
((SELECT id FROM categories WHERE name='Health & Wellness'), 'Medical Equipment'),
((SELECT id FROM categories WHERE name='Health & Wellness'), 'Mental Health & Coaching')
ON CONFLICT (category_id, name) DO NOTHING;

-- Home & Living
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Home & Living'), 'Furniture'),
((SELECT id FROM categories WHERE name='Home & Living'), 'Interior Decor'),
((SELECT id FROM categories WHERE name='Home & Living'), 'Kitchen & Appliances'),
((SELECT id FROM categories WHERE name='Home & Living'), 'Cleaning Supplies'),
((SELECT id FROM categories WHERE name='Home & Living'), 'Bedding & Fabrics')
ON CONFLICT (category_id, name) DO NOTHING;

-- Logistics & Transport
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Logistics & Transport'), 'Last-Mile Delivery'),
((SELECT id FROM categories WHERE name='Logistics & Transport'), 'Freight & Haulage'),
((SELECT id FROM categories WHERE name='Logistics & Transport'), 'Warehousing & Storage'),
((SELECT id FROM categories WHERE name='Logistics & Transport'), 'Dispatch & Courier'),
((SELECT id FROM categories WHERE name='Logistics & Transport'), 'Vehicle Rentals')
ON CONFLICT (category_id, name) DO NOTHING;

-- Professional Services
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Professional Services'), 'Accounting & Bookkeeping'),
((SELECT id FROM categories WHERE name='Professional Services'), 'Legal Services'),
((SELECT id FROM categories WHERE name='Professional Services'), 'Consulting & Advisory'),
((SELECT id FROM categories WHERE name='Professional Services'), 'Marketing & Advertising'),
((SELECT id FROM categories WHERE name='Professional Services'), 'Graphic Design'),
((SELECT id FROM categories WHERE name='Professional Services'), 'Web & App Development'),
((SELECT id FROM categories WHERE name='Professional Services'), 'Photography & Videography')
ON CONFLICT (category_id, name) DO NOTHING;

-- Agriculture & Raw Materials
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Agriculture & Raw Materials'), 'Crop Farming'),
((SELECT id FROM categories WHERE name='Agriculture & Raw Materials'), 'Livestock & Poultry'),
((SELECT id FROM categories WHERE name='Agriculture & Raw Materials'), 'Fish & Aquaculture'),
((SELECT id FROM categories WHERE name='Agriculture & Raw Materials'), 'Agro-Processing'),
((SELECT id FROM categories WHERE name='Agriculture & Raw Materials'), 'Farm Inputs & Equipment')
ON CONFLICT (category_id, name) DO NOTHING;

-- Education & Training
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Education & Training'), 'Tutoring & Test Prep'),
((SELECT id FROM categories WHERE name='Education & Training'), 'Professional Certification'),
((SELECT id FROM categories WHERE name='Education & Training'), 'Online Courses & E-Learning'),
((SELECT id FROM categories WHERE name='Education & Training'), 'Vocational Training'),
((SELECT id FROM categories WHERE name='Education & Training'), 'School Supplies & Books')
ON CONFLICT (category_id, name) DO NOTHING;

-- Media & Entertainment
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Media & Entertainment'), 'Music Production'),
((SELECT id FROM categories WHERE name='Media & Entertainment'), 'Event Planning'),
((SELECT id FROM categories WHERE name='Media & Entertainment'), 'Content Creation'),
((SELECT id FROM categories WHERE name='Media & Entertainment'), 'Printing & Publishing'),
((SELECT id FROM categories WHERE name='Media & Entertainment'), 'DJ & Sound Equipment')
ON CONFLICT (category_id, name) DO NOTHING;

-- Construction & Real Estate
INSERT INTO micro_niches (category_id, name) VALUES
((SELECT id FROM categories WHERE name='Construction & Real Estate'), 'Building Materials'),
((SELECT id FROM categories WHERE name='Construction & Real Estate'), 'Property Sales & Rentals'),
((SELECT id FROM categories WHERE name='Construction & Real Estate'), 'Interior Finishing'),
((SELECT id FROM categories WHERE name='Construction & Real Estate'), 'Plumbing & Electrical'),
((SELECT id FROM categories WHERE name='Construction & Real Estate'), 'Architecture & Drafting')
ON CONFLICT (category_id, name) DO NOTHING;

-- ============================================================
-- SEED INITIAL VERIFICATION CODES
-- ============================================================
INSERT INTO verification_codes (code, expires_at) VALUES
('BSQ001', CURRENT_TIMESTAMP + INTERVAL '90 days'),
('BSQ002', CURRENT_TIMESTAMP + INTERVAL '90 days'),
('BSQ003', CURRENT_TIMESTAMP + INTERVAL '90 days'),
('BSQ004', CURRENT_TIMESTAMP + INTERVAL '90 days'),
('BSQ005', CURRENT_TIMESTAMP + INTERVAL '90 days'),
('DEMO01', CURRENT_TIMESTAMP + INTERVAL '365 days'),
('TEST01', CURRENT_TIMESTAMP + INTERVAL '365 days')
ON CONFLICT (code) DO NOTHING;
