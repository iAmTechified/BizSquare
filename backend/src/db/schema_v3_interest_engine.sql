-- ==============================================================================
-- BIZSQUARE SCHEMA V3: INTEREST & DEMAND SYSTEM + CONTENT ENGINE
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. INTEREST TAXONOMIES (Hierarchical Nodes)
CREATE TABLE IF NOT EXISTS interest_taxonomies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    parent_id UUID REFERENCES interest_taxonomies(id) ON DELETE SET NULL,
    description TEXT,
    context_type VARCHAR(50) DEFAULT 'general', -- general, business, personal, lifestyle, consumer, emerging
    icon VARCHAR(100) DEFAULT 'category',
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    aliases TEXT[] DEFAULT '{}',
    content_count INT DEFAULT 0,
    active_content_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interest_taxonomies_parent ON interest_taxonomies(parent_id);
CREATE INDEX IF NOT EXISTS idx_interest_taxonomies_context ON interest_taxonomies(context_type);
CREATE INDEX IF NOT EXISTS idx_interest_taxonomies_slug ON interest_taxonomies(slug);

-- 2. INTEREST TAXONOMY RELATIONSHIPS (Soft Semantic Graph)
CREATE TABLE IF NOT EXISTS interest_taxonomy_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID NOT NULL REFERENCES interest_taxonomies(id) ON DELETE CASCADE,
    target_id UUID NOT NULL REFERENCES interest_taxonomies(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) DEFAULT 'related', -- related, adjacent, prerequisite, subcategory
    weight NUMERIC(3,2) DEFAULT 0.75, -- 0.0 to 1.0
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_taxonomy_relationship UNIQUE (source_id, target_id, relationship_type)
);

CREATE INDEX IF NOT EXISTS idx_tax_rel_source ON interest_taxonomy_relationships(source_id);
CREATE INDEX IF NOT EXISTS idx_tax_rel_target ON interest_taxonomy_relationships(target_id);

-- 3. USER BASELINE INTERESTS (Explicit initial onboarding/profile selections)
CREATE TABLE IF NOT EXISTS user_baseline_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    taxonomy_id UUID NOT NULL REFERENCES interest_taxonomies(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_user_baseline_taxonomy UNIQUE (user_id, taxonomy_id)
);

CREATE INDEX IF NOT EXISTS idx_user_baseline_user ON user_baseline_interests(user_id);

-- 4. RAW IMMUTABLE INTERACTION EVENTS (Ledger with event_id idempotency)
CREATE TABLE IF NOT EXISTS interest_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID,
    content_id UUID,
    format VARCHAR(50) NOT NULL,
    option_id VARCHAR(100),
    interaction_type VARCHAR(50) NOT NULL, -- view, tap, select, react, skip, swipe_left, swipe_right, complete
    dwell_ms INT DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interest_events_user ON interest_events(user_id);
CREATE INDEX IF NOT EXISTS idx_interest_events_session ON interest_events(session_id);
CREATE INDEX IF NOT EXISTS idx_interest_events_content ON interest_events(content_id);
CREATE INDEX IF NOT EXISTS idx_interest_events_created ON interest_events(created_at);

-- 5. DERIVED INTEREST SIGNALS (Resolved from interaction options)
CREATE TABLE IF NOT EXISTS interest_signals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES interest_events(event_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    taxonomy_id UUID NOT NULL REFERENCES interest_taxonomies(id) ON DELETE CASCADE,
    signal_type VARCHAR(50) NOT NULL, -- positive, weak_positive, negative, neutral, intent, context
    weight NUMERIC(4,2) DEFAULT 1.0,
    context VARCHAR(50) DEFAULT 'general',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interest_signals_user ON interest_signals(user_id);
CREATE INDEX IF NOT EXISTS idx_interest_signals_tax ON interest_signals(taxonomy_id);
CREATE INDEX IF NOT EXISTS idx_interest_signals_created ON interest_signals(created_at);

-- 6. USER INTEREST STATES (Multi-state graph model with recency & confidence)
CREATE TABLE IF NOT EXISTS user_interest_states (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    taxonomy_id UUID NOT NULL REFERENCES interest_taxonomies(id) ON DELETE CASCADE,
    state VARCHAR(50) DEFAULT 'EMERGING', -- EMERGING, ACTIVE, ONGOING, DORMANT, SUPPRESSED
    strength NUMERIC(4,3) DEFAULT 0.200, -- 0.000 to 1.000
    confidence NUMERIC(4,3) DEFAULT 0.100, -- 0.000 to 1.000
    recency_score NUMERIC(4,3) DEFAULT 1.000, -- decayed over time
    frequency_count INT DEFAULT 1,
    positive_signal_count INT DEFAULT 1,
    negative_signal_count INT DEFAULT 0,
    last_positive_at TIMESTAMP WITH TIME ZONE,
    last_negative_at TIMESTAMP WITH TIME ZONE,
    first_observed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_observed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    context_prob JSONB DEFAULT '{"personal": 0.5, "business": 0.5}',
    source_summary VARCHAR(100) DEFAULT 'daily_wall',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_user_taxonomy_state UNIQUE (user_id, taxonomy_id)
);

CREATE INDEX IF NOT EXISTS idx_user_interest_user_state ON user_interest_states(user_id, state);
CREATE INDEX IF NOT EXISTS idx_user_interest_strength ON user_interest_states(user_id, strength DESC);

-- 7. CONTENT GENERATION BATCHES
CREATE TABLE IF NOT EXISTS content_generation_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    taxonomy_id UUID REFERENCES interest_taxonomies(id) ON DELETE SET NULL,
    formats TEXT[] NOT NULL DEFAULT '{}',
    context_type VARCHAR(50) DEFAULT 'mixed',
    target_audience VARCHAR(100) DEFAULT 'general',
    target_quantity INT DEFAULT 10,
    generated_quantity INT DEFAULT 0,
    approved_quantity INT DEFAULT 0,
    rejected_quantity INT DEFAULT 0,
    status VARCHAR(50) DEFAULT 'COMPLETED', -- GENERATING, COMPLETED, FAILED
    prompt_config JSONB DEFAULT '{}',
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. CONTENT ITEMS (Content Bank)
CREATE TABLE IF NOT EXISTS content_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    format VARCHAR(50) NOT NULL, -- THIS_OR_THAT, PICK_ONE, WOULD_YOU, REACTION_CARD, SCENARIO, COMPARE, QUICK_OPINION, INTENT_CHOICE
    status VARCHAR(50) DEFAULT 'REVIEW', -- DRAFT, GENERATING, REVIEW, APPROVED, ACTIVE, PAUSED, ARCHIVED, REJECTED
    title_prompt TEXT NOT NULL,
    description TEXT,
    media_url TEXT,
    media_type VARCHAR(50) DEFAULT 'none', -- none, image, icon, animation
    context_type VARCHAR(50) DEFAULT 'general', -- general, business, personal, lifestyle, consumer, emerging
    target_audience VARCHAR(100) DEFAULT 'general',
    difficulty VARCHAR(50) DEFAULT 'normal', -- simple, normal, advanced
    version INT DEFAULT 1,
    batch_id UUID REFERENCES content_generation_batches(id) ON DELETE SET NULL,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_content_items_status ON content_items(status);
CREATE INDEX IF NOT EXISTS idx_content_items_format ON content_items(format);

-- 9. CONTENT TAXONOMY LINKS
CREATE TABLE IF NOT EXISTS content_taxonomy_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    taxonomy_id UUID NOT NULL REFERENCES interest_taxonomies(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT TRUE,
    CONSTRAINT uq_content_taxonomy UNIQUE (content_id, taxonomy_id)
);

CREATE INDEX IF NOT EXISTS idx_content_tax_links_tax ON content_taxonomy_links(taxonomy_id);

-- 10. CONTENT OPTIONS
CREATE TABLE IF NOT EXISTS content_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    option_key VARCHAR(100) NOT NULL, -- opt_a, opt_b, yes, no, etc.
    label TEXT NOT NULL,
    subtext TEXT,
    media_url TEXT,
    order_index INT DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_content_options_content ON content_options(content_id);

-- 11. CONTENT SIGNAL MAPPINGS (Option -> Taxonomy Signals)
CREATE TABLE IF NOT EXISTS content_signal_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES content_options(id) ON DELETE CASCADE,
    taxonomy_id UUID NOT NULL REFERENCES interest_taxonomies(id) ON DELETE CASCADE,
    signal_type VARCHAR(50) DEFAULT 'positive', -- positive, weak_positive, negative, neutral, intent, context
    weight NUMERIC(4,2) DEFAULT 1.0,
    context VARCHAR(50) DEFAULT 'general'
);

CREATE INDEX IF NOT EXISTS idx_content_signals_option ON content_signal_mappings(option_id);

-- 12. CONTENT REVIEWS & VERSIONS
CREATE TABLE IF NOT EXISTS content_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    reviewer_id UUID,
    decision VARCHAR(50) NOT NULL, -- APPROVE, REJECT, EDIT, PAUSE
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS content_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    snapshot JSONB NOT NULL,
    edited_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. CONTENT PERFORMANCE METRICS
CREATE TABLE IF NOT EXISTS content_performance (
    content_id UUID PRIMARY KEY REFERENCES content_items(id) ON DELETE CASCADE,
    impressions_count INT DEFAULT 0,
    interactions_count INT DEFAULT 0,
    skips_count INT DEFAULT 0,
    completions_count INT DEFAULT 0,
    avg_dwell_ms INT DEFAULT 0,
    positive_signals_generated INT DEFAULT 0,
    last_served_at TIMESTAMP WITH TIME ZONE
);

-- 14. WALL SESSIONS & REPRODUCIBLE SESSION LOGS
CREATE TABLE IF NOT EXISTS wall_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    item_count INT DEFAULT 5,
    status VARCHAR(50) DEFAULT 'STARTED', -- STARTED, COMPLETED, ABANDONED
    target_mix JSONB DEFAULT '{"personalized": 0.40, "related": 0.25, "exploration": 0.20, "broad": 0.15}',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_wall_sessions_user ON wall_sessions(user_id, date);

CREATE TABLE IF NOT EXISTS wall_session_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES wall_sessions(session_id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    order_index INT NOT NULL,
    pool_type VARCHAR(50) DEFAULT 'PERSONALIZED', -- PERSONALIZED, RELATED, EXPLORATION, BROAD
    served_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wall_session_items_session ON wall_session_items(session_id);

CREATE TABLE IF NOT EXISTS wall_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES wall_sessions(session_id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    option_id VARCHAR(100),
    interaction_type VARCHAR(50) NOT NULL,
    dwell_ms INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- SEED DATA: 10 BROAD CATEGORIES & 80+ GRANULAR TAXONOMIES
-- ==============================================================================

-- 1. Technology
INSERT INTO interest_taxonomies (slug, name, context_type, icon, sort_order)
VALUES ('tech', 'Technology', 'general', 'devices', 1)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO interest_taxonomies (slug, name, parent_id, context_type, icon, aliases)
SELECT s.slug, s.name, p.id, s.context_type, s.icon, s.aliases
FROM (VALUES
    ('tech_smartphones', 'Smartphones & Mobile Devices', 'consumer', 'smartphone', ARRAY['phones', 'android', 'iphone', 'handsets']),
    ('tech_laptops_pc', 'Laptops & Computers', 'business', 'laptop', ARRAY['computers', 'macbook', 'workstations']),
    ('tech_audio', 'Audio & Headphones', 'consumer', 'headphones', ARRAY['earbuds', 'speakers', 'sound systems']),
    ('tech_smart_home', 'Smart Home & IoT Devices', 'lifestyle', 'home', ARRAY['smart gadgets', 'automation', 'security cams']),
    ('tech_software_apps', 'Software & Mobile Apps', 'business', 'apps', ARRAY['saas', 'cloud', 'developer tools']),
    ('tech_accessories', 'Gadget Accessories & Power', 'consumer', 'cable', ARRAY['chargers', 'power banks', 'cases']),
    ('tech_gaming', 'Gaming & Consoles', 'lifestyle', 'gamepad', ARRAY['playstation', 'xbox', 'gaming pc'])
) AS s(slug, name, context_type, icon, aliases)
CROSS JOIN interest_taxonomies p WHERE p.slug = 'tech'
ON CONFLICT (slug) DO NOTHING;

-- 2. Fashion & Apparel
INSERT INTO interest_taxonomies (slug, name, context_type, icon, sort_order)
VALUES ('fashion', 'Fashion & Apparel', 'lifestyle', 'checkroom', 2)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO interest_taxonomies (slug, name, parent_id, context_type, icon, aliases)
SELECT s.slug, s.name, p.id, s.context_type, s.icon, s.aliases
FROM (VALUES
    ('fashion_footwear', 'Footwear & Sneakers', 'consumer', 'snowshoe', ARRAY['shoes', 'boots', 'heels', 'loafers']),
    ('fashion_watches', 'Watches & Smartwatches', 'lifestyle', 'watch', ARRAY['timepieces', 'luxury watches']),
    ('fashion_streetwear', 'Streetwear & Casual Apparel', 'consumer', 'style', ARRAY['t-shirts', 'hoodies', 'denim']),
    ('fashion_formal', 'Corporate & Formal Wear', 'business', 'dry_cleaning', ARRAY['suits', 'blazers', 'corporate shirts']),
    ('fashion_bags', 'Bags & Luggage', 'lifestyle', 'luggage', ARRAY['handbags', 'backpacks', 'briefcases']),
    ('fashion_jewelry', 'Jewelry & Accessories', 'lifestyle', 'diamond', ARRAY['chains', 'rings', 'bracelets'])
) AS s(slug, name, context_type, icon, aliases)
CROSS JOIN interest_taxonomies p WHERE p.slug = 'fashion'
ON CONFLICT (slug) DO NOTHING;

-- 3. Professional & Business Services
INSERT INTO interest_taxonomies (slug, name, context_type, icon, sort_order)
VALUES ('services', 'Professional & Business Services', 'business', 'work', 3)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO interest_taxonomies (slug, name, parent_id, context_type, icon, aliases)
SELECT s.slug, s.name, p.id, s.context_type, s.icon, s.aliases
FROM (VALUES
    ('services_marketing', 'Digital Marketing & Growth', 'business', 'campaign', ARRAY['advertising', 'seo', 'social media ads']),
    ('services_delivery', 'Logistics & Dispatch Delivery', 'business', 'local_shipping', ARRAY['courier', 'freight', 'last mile']),
    ('services_branding', 'Graphic Design & Brand Identity', 'business', 'design_services', ARRAY['logos', 'flyers', 'ui ux']),
    ('services_legal_audit', 'Accounting, Tax & Legal', 'business', 'gavel', ARRAY['cac registration', 'bookkeeping', 'audit']),
    ('services_repairs', 'Electronics & Hardware Repair', 'business', 'build', ARRAY['phone fix', 'laptop maintenance']),
    ('services_printing', 'Packaging & Commercial Printing', 'business', 'print', ARRAY['custom boxes', 'labels', 'stationery'])
) AS s(slug, name, context_type, icon, aliases)
CROSS JOIN interest_taxonomies p WHERE p.slug = 'services'
ON CONFLICT (slug) DO NOTHING;

-- 4. Food, Beverage & Dining
INSERT INTO interest_taxonomies (slug, name, context_type, icon, sort_order)
VALUES ('food', 'Food & Beverage', 'lifestyle', 'restaurant', 4)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO interest_taxonomies (slug, name, parent_id, context_type, icon, aliases)
SELECT s.slug, s.name, p.id, s.context_type, s.icon, s.aliases
FROM (VALUES
    ('food_restaurants', 'Restaurants & Fine Dining', 'lifestyle', 'restaurant_menu', ARRAY['eateries', 'fast food', 'cafes']),
    ('food_bakery', 'Bakery & Confectionery', 'consumer', 'bakery_dining', ARRAY['cakes', 'pastries', 'bread']),
    ('food_groceries', 'Fresh Groceries & Farm Produce', 'consumer', 'shopping_cart', ARRAY['vegetables', 'meat', 'bulk foodstuffs']),
    ('food_drinks', 'Specialty Drinks & Beverages', 'consumer', 'local_bar', ARRAY['cocktails', 'juices', 'coffee', 'wine']),
    ('food_catering', 'Catering & Event Food Supply', 'business', 'soup_kitchen', ARRAY['bulk cooking', 'party trays'])
) AS s(slug, name, context_type, icon, aliases)
CROSS JOIN interest_taxonomies p WHERE p.slug = 'food'
ON CONFLICT (slug) DO NOTHING;

-- 5. Lifestyle, Health & Wellness
INSERT INTO interest_taxonomies (slug, name, context_type, icon, sort_order)
VALUES ('lifestyle', 'Lifestyle & Wellness', 'lifestyle', 'spa', 5)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO interest_taxonomies (slug, name, parent_id, context_type, icon, aliases)
SELECT s.slug, s.name, p.id, s.context_type, s.icon, s.aliases
FROM (VALUES
    ('life_fitness', 'Fitness & Gym Workouts', 'lifestyle', 'fitness_center', ARRAY['bodybuilding', 'running', 'gym equipment']),
    ('life_travel', 'Travel, Tourism & Getaways', 'lifestyle', 'flight', ARRAY['vacations', 'resorts', 'hotel bookings']),
    ('life_skincare', 'Skincare & Organic Beauty', 'consumer', 'face', ARRAY['cosmetics', 'serums', 'sunscreen']),
    ('life_wellness', 'Mental Wellness & Relaxation', 'lifestyle', 'self_improvement', ARRAY['meditation', 'retreats', 'massage']),
    ('life_events', 'Events, Concerts & Nightlife', 'lifestyle', 'celebration', ARRAY['festivals', 'parties', 'tickets'])
) AS s(slug, name, context_type, icon, aliases)
CROSS JOIN interest_taxonomies p WHERE p.slug = 'lifestyle'
ON CONFLICT (slug) DO NOTHING;

-- 6. Home, Office & Real Estate
INSERT INTO interest_taxonomies (slug, name, context_type, icon, sort_order)
VALUES ('home', 'Home, Office & Real Estate', 'general', 'apartment', 6)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO interest_taxonomies (slug, name, parent_id, context_type, icon, aliases)
SELECT s.slug, s.name, p.id, s.context_type, s.icon, s.aliases
FROM (VALUES
    ('home_furniture', 'Modern Furniture & Decor', 'lifestyle', 'chair', ARRAY['office chairs', 'couches', 'interior decor']),
    ('home_appliances', 'Kitchen & Home Appliances', 'consumer', 'kitchen', ARRAY['fridges', 'microwaves', 'air conditioners']),
    ('home_solar', 'Solar & Renewable Energy', 'business', 'solar_power', ARRAY['inverters', 'batteries', 'solar panels']),
    ('home_real_estate', 'Commercial & Residential Real Estate', 'business', 'real_estate_agent', ARRAY['apartments', 'rentals', 'office space'])
) AS s(slug, name, context_type, icon, aliases)
CROSS JOIN interest_taxonomies p WHERE p.slug = 'home'
ON CONFLICT (slug) DO NOTHING;

-- 7. Emerging Interests & Creative Arts
INSERT INTO interest_taxonomies (slug, name, context_type, icon, sort_order)
VALUES ('creative', 'Creative Arts & Media', 'emerging', 'palette', 7)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO interest_taxonomies (slug, name, parent_id, context_type, icon, aliases)
SELECT s.slug, s.name, p.id, s.context_type, s.icon, s.aliases
FROM (VALUES
    ('creative_photography', 'Photography & Video Production', 'emerging', 'camera_alt', ARRAY['cameras', 'shoots', 'video editing']),
    ('creative_podcasting', 'Podcasting & Content Creation', 'emerging', 'mic', ARRAY['youtube', 'streaming', 'audio gear']),
    ('creative_music', 'Music Production & Instruments', 'emerging', 'music_note', ARRAY['guitars', 'keyboards', 'studio equipment'])
) AS s(slug, name, context_type, icon, aliases)
CROSS JOIN interest_taxonomies p WHERE p.slug = 'creative'
ON CONFLICT (slug) DO NOTHING;

-- ==============================================================================
-- SEED SOFT SEMANTIC RELATIONSHIPS (For exploration & adjacent interest discovery)
-- ==============================================================================

-- Smartphones <-> Audio & Headphones
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'adjacent', 0.85
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'tech_smartphones' AND b.slug = 'tech_audio'
ON CONFLICT DO NOTHING;

-- Smartphones <-> Photography
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'related', 0.80
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'tech_smartphones' AND b.slug = 'creative_photography'
ON CONFLICT DO NOTHING;

-- Laptops <-> Digital Marketing
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'related', 0.75
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'tech_laptops_pc' AND b.slug = 'services_marketing'
ON CONFLICT DO NOTHING;

-- Footwear <-> Streetwear
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'related', 0.90
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'fashion_footwear' AND b.slug = 'fashion_streetwear'
ON CONFLICT DO NOTHING;

-- Watches <-> Formal Wear
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'related', 0.85
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'fashion_watches' AND b.slug = 'fashion_formal'
ON CONFLICT DO NOTHING;

-- Packaging <-> Logistics Delivery
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'adjacent', 0.90
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'services_printing' AND b.slug = 'services_delivery'
ON CONFLICT DO NOTHING;

-- Fitness <-> Travel
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'adjacent', 0.70
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'life_fitness' AND b.slug = 'life_travel'
ON CONFLICT DO NOTHING;

-- Solar Energy <-> Home Appliances
INSERT INTO interest_taxonomy_relationships (source_id, target_id, relationship_type, weight)
SELECT a.id, b.id, 'adjacent', 0.80
FROM interest_taxonomies a, interest_taxonomies b
WHERE a.slug = 'home_solar' AND b.slug = 'home_appliances'
ON CONFLICT DO NOTHING;

-- ==============================================================================
-- SEED 8 MULTI-FORMAT CURATED CONTENT ITEMS (Active in Content Bank)
-- ==============================================================================

-- 1. Format: THIS_OR_THAT (Technology: Phone vs Laptop)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'THIS_OR_THAT', 'ACTIVE',
        'Which would you rather upgrade right now?',
        'Preference between mobile smartphone hardware and portable workstation laptops.',
        'general', 'general', NOW()
    )
    RETURNING id
),
opt_a AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_a', 'Latest Flagship Smartphone', 'Top camera, battery & speed', 1 FROM inserted_content
    RETURNING id, content_id
),
opt_b AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_b', 'High-Performance Work Laptop', 'M3 / Core i9 speed for work', 2 FROM inserted_content
    RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_smartphones'
    UNION ALL
    SELECT c.id, t.id, FALSE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_laptops_pc'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'consumer'
FROM opt_a o CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_smartphones'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'business'
FROM opt_b o CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_laptops_pc';

-- 2. Format: WOULD_YOU (Audio: Wireless Noise-Cancelling Earbuds)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'WOULD_YOU', 'ACTIVE',
        'Would you invest in high-fidelity noise-cancelling earbuds for daily commuting & calls?',
        'Explores audio gear interest and quiet work environment preference.',
        'lifestyle', 'general', NOW()
    )
    RETURNING id
),
opt_yes AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'yes', 'Definitely Yes 🔥', 'I value crystal clear sound & silence', 1 FROM inserted_content
    RETURNING id, content_id
),
opt_maybe AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'maybe', 'Maybe / If Budget Allows', 'Curious about good audio', 2 FROM inserted_content
    RETURNING id, content_id
),
opt_no AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'no', 'Not for Me', 'Standard earphones work fine', 3 FROM inserted_content
    RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_audio'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'consumer' FROM opt_yes o CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_audio'
UNION ALL
SELECT o.content_id, o.id, t.id, 'weak_positive', 0.5, 'consumer' FROM opt_maybe o CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_audio'
UNION ALL
SELECT o.content_id, o.id, t.id, 'negative', -0.5, 'consumer' FROM opt_no o CROSS JOIN interest_taxonomies t WHERE t.slug = 'tech_audio';

-- 3. Format: PICK_ONE (Fashion / Footwear vs Watches vs Bags vs Formal)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'PICK_ONE', 'ACTIVE',
        'Which fashion category do you prioritize refreshing in your wardrobe first?',
        'Identifies primary fashion and apparel inclination.',
        'lifestyle', 'general', NOW()
    )
    RETURNING id
),
opt_1 AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_shoes', 'Premium Sneakers & Footwear', 'Comfort & statement shoes', 1 FROM inserted_content RETURNING id, content_id
),
opt_2 AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_watch', 'Luxury Wristwatches', 'Class & timeless appeal', 2 FROM inserted_content RETURNING id, content_id
),
opt_3 AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_bag', 'Leather Bags & Backpacks', 'Work travel & everyday carry', 3 FROM inserted_content RETURNING id, content_id
),
opt_4 AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_formal', 'Tailored Corporate Blazers & Suits', 'Professional elegance', 4 FROM inserted_content RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'fashion_footwear'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'consumer' FROM opt_1 o CROSS JOIN interest_taxonomies t WHERE t.slug = 'fashion_footwear'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'lifestyle' FROM opt_2 o CROSS JOIN interest_taxonomies t WHERE t.slug = 'fashion_watches'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'lifestyle' FROM opt_3 o CROSS JOIN interest_taxonomies t WHERE t.slug = 'fashion_bags'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'business' FROM opt_4 o CROSS JOIN interest_taxonomies t WHERE t.slug = 'fashion_formal';

-- 4. Format: SCENARIO (Business Priorities: ₦100,000 budget allocation)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'SCENARIO', 'ACTIVE',
        'You receive a ₦100,000 growth grant this week. Where does it create the most impact?',
        'Reveals operational urgency and commercial bottlenecks.',
        'business', 'business', NOW()
    )
    RETURNING id
),
opt_a AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_ads', 'Targeted Ads & Customer Acquisition', 'Drive direct leads & orders', 1 FROM inserted_content RETURNING id, content_id
),
opt_b AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_dispatch', 'Reliable Same-Day Logistics Partner', 'Eliminate delivery delays', 2 FROM inserted_content RETURNING id, content_id
),
opt_c AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_brand', 'Packaging & Premium Branding', 'Elevate unboxing experience', 3 FROM inserted_content RETURNING id, content_id
),
opt_d AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_solar', 'Solar Backup Energy System', 'Keep operations running 24/7', 4 FROM inserted_content RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'services_marketing'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'business' FROM opt_a o CROSS JOIN interest_taxonomies t WHERE t.slug = 'services_marketing'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'business' FROM opt_b o CROSS JOIN interest_taxonomies t WHERE t.slug = 'services_delivery'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'business' FROM opt_c o CROSS JOIN interest_taxonomies t WHERE t.slug = 'services_printing'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'business' FROM opt_d o CROSS JOIN interest_taxonomies t WHERE t.slug = 'home_solar';

-- 5. Format: REACTION_CARD (Emerging: Content Creation & Photography Studio)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'REACTION_CARD', 'ACTIVE',
        'Mobile 4K Video Rig & Studio Lighting for Product Showcases',
        'Reaction card testing emerging interest in video creation and photography tools.',
        'emerging', 'general', NOW()
    )
    RETURNING id
),
opt_heart AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'react_love', '❤️ Interested', 'I want to create sharper media', 1 FROM inserted_content RETURNING id, content_id
),
opt_eye AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'react_curious', '👀 Curious', 'Want to see samples first', 2 FROM inserted_content RETURNING id, content_id
),
opt_skip AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'react_skip', '⏭️ Skip', 'Not relevant right now', 3 FROM inserted_content RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'creative_photography'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'emerging' FROM opt_heart o CROSS JOIN interest_taxonomies t WHERE t.slug = 'creative_photography'
UNION ALL
SELECT o.content_id, o.id, t.id, 'weak_positive', 0.5, 'emerging' FROM opt_eye o CROSS JOIN interest_taxonomies t WHERE t.slug = 'creative_photography'
UNION ALL
SELECT o.content_id, o.id, t.id, 'neutral', 0.0, 'general' FROM opt_skip o CROSS JOIN interest_taxonomies t WHERE t.slug = 'creative_photography';

-- 6. Format: COMPARE (Food: Artisanal Bakery vs Gourmet Restaurant)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'COMPARE', 'ACTIVE',
        'Which culinary experience sounds more appealing for your weekend treat?',
        'Compares freshly baked pastries vs a gourmet restaurant experience.',
        'lifestyle', 'general', NOW()
    )
    RETURNING id
),
opt_a AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_bakery', 'Artisanal Bakery & Dessert Box', 'Freshly baked pastries & confectionery', 1 FROM inserted_content RETURNING id, content_id
),
opt_b AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_dine', '3-Course Gourmet Restaurant Dinner', 'Fine dining & vibrant ambience', 2 FROM inserted_content RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'food_bakery'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'lifestyle' FROM opt_a o CROSS JOIN interest_taxonomies t WHERE t.slug = 'food_bakery'
UNION ALL
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'lifestyle' FROM opt_b o CROSS JOIN interest_taxonomies t WHERE t.slug = 'food_restaurants';

-- 7. Format: QUICK_OPINION (Lifestyle / Fitness: High-Intensity Workout Class)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'QUICK_OPINION', 'ACTIVE',
        'Early morning 45-minute HIIT workout session to boost daily energy: Worth it?',
        'Quick opinion on fitness, discipline, and wellness habits.',
        'lifestyle', 'general', NOW()
    )
    RETURNING id
),
opt_1 AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_def', 'Definitely Worth It 💪', 'Energizes the entire day', 1 FROM inserted_content RETURNING id, content_id
),
opt_2 AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_maybe', 'Maybe on Weekends', 'Hard to wake up early', 2 FROM inserted_content RETURNING id, content_id
),
opt_3 AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'opt_no', 'Not for Me', 'Prefer evening leisure', 3 FROM inserted_content RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'life_fitness'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'positive', 1.0, 'lifestyle' FROM opt_1 o CROSS JOIN interest_taxonomies t WHERE t.slug = 'life_fitness'
UNION ALL
SELECT o.content_id, o.id, t.id, 'weak_positive', 0.4, 'lifestyle' FROM opt_2 o CROSS JOIN interest_taxonomies t WHERE t.slug = 'life_fitness'
UNION ALL
SELECT o.content_id, o.id, t.id, 'negative', -0.3, 'lifestyle' FROM opt_3 o CROSS JOIN interest_taxonomies t WHERE t.slug = 'life_fitness';

-- 8. Format: INTENT_CHOICE (Business / Clean Energy: Solar Inverter Installation)
WITH inserted_content AS (
    INSERT INTO content_items (format, status, title_prompt, description, context_type, target_audience, published_at)
    VALUES (
        'INTENT_CHOICE', 'ACTIVE',
        'If a verified vendor offers zero-downtime solar inverter setup with flexible payment:',
        'Detects active purchase intent and consideration for renewable solar energy.',
        'business', 'business', NOW()
    )
    RETURNING id
),
opt_a AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'act_now', 'Get Quote Now ⚡', 'I need reliable power urgently', 1 FROM inserted_content RETURNING id, content_id
),
opt_b AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'act_wait', 'Save for Later', 'Planning for next quarter', 2 FROM inserted_content RETURNING id, content_id
),
opt_c AS (
    INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
    SELECT id, 'act_alt', 'Explore Alternatives', 'Considering other power options', 3 FROM inserted_content RETURNING id, content_id
),
link_tax AS (
    INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary)
    SELECT c.id, t.id, TRUE FROM inserted_content c CROSS JOIN interest_taxonomies t WHERE t.slug = 'home_solar'
)
INSERT INTO content_signal_mappings (content_id, option_id, taxonomy_id, signal_type, weight, context)
SELECT o.content_id, o.id, t.id, 'intent', 1.5, 'business' FROM opt_a o CROSS JOIN interest_taxonomies t WHERE t.slug = 'home_solar'
UNION ALL
SELECT o.content_id, o.id, t.id, 'weak_positive', 0.6, 'business' FROM opt_b o CROSS JOIN interest_taxonomies t WHERE t.slug = 'home_solar'
UNION ALL
SELECT o.content_id, o.id, t.id, 'neutral', 0.2, 'business' FROM opt_c o CROSS JOIN interest_taxonomies t WHERE t.slug = 'home_solar';

-- Update active content counts for taxonomies
UPDATE interest_taxonomies t
SET 
    content_count = (SELECT COUNT(*) FROM content_taxonomy_links ctl WHERE ctl.taxonomy_id = t.id),
    active_content_count = (
        SELECT COUNT(*) 
        FROM content_taxonomy_links ctl 
        JOIN content_items ci ON ci.id = ctl.content_id 
        WHERE ctl.taxonomy_id = t.id AND ci.status = 'ACTIVE'
    );
