-- BizSquare Schema V12: Migrate categories & micro_niches to stable string slug IDs
-- This is an idempotent migration safe to run multiple times.

-- Step 1: Make id columns VARCHAR if they are currently UUID (check first, then alter)
-- We need to drop FK constraints, alter the PK columns, re-add FKs.
-- Since this is complex, the safest approach on a live/new DB is:
-- a) Add new slug columns alongside existing columns
-- b) Drop old FKs
-- c) Set slug as new PK
-- d) Update all FK references

-- Because this is likely a dev DB that can be re-seeded, just DROP and RECREATE with the correct type.

-- Drop dependent tables first (reverse dependency order)
DROP TABLE IF EXISTS spotlight_flyers CASCADE;
DROP TABLE IF EXISTS broadcasts CASCADE;
DROP TABLE IF EXISTS crm_contacts CASCADE;
DROP TABLE IF EXISTS activity_feed CASCADE;
DROP TABLE IF EXISTS match_queue CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS dynamic_demand CASCADE;
DROP TABLE IF EXISTS baseline_demand CASCADE;
DROP TABLE IF EXISTS business_micro_niches CASCADE;
DROP TABLE IF EXISTS micro_niches CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- Recreate categories with VARCHAR slug PK
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Recreate micro_niches with VARCHAR slug PK and VARCHAR category_id FK
CREATE TABLE IF NOT EXISTS micro_niches (
    id VARCHAR(100) PRIMARY KEY,
    category_id VARCHAR(50) NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(category_id, name)
);

CREATE INDEX IF NOT EXISTS idx_micro_niches_category ON micro_niches(category_id);

-- Recreate business_micro_niches with VARCHAR micro_niche_id FK
CREATE TABLE IF NOT EXISTS business_micro_niches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    micro_niche_id VARCHAR(100) NOT NULL REFERENCES micro_niches(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, micro_niche_id)
);

CREATE INDEX IF NOT EXISTS idx_bmn_user ON business_micro_niches(user_id);
CREATE INDEX IF NOT EXISTS idx_bmn_niche ON business_micro_niches(micro_niche_id);

-- Recreate baseline_demand with VARCHAR micro_niche_id FK
CREATE TABLE IF NOT EXISTS baseline_demand (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    micro_niche_id VARCHAR(100) NOT NULL REFERENCES micro_niches(id) ON DELETE CASCADE,
    source VARCHAR(20) DEFAULT 'onboarding',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, micro_niche_id)
);

CREATE INDEX IF NOT EXISTS idx_baseline_user ON baseline_demand(user_id);

-- Recreate dynamic_demand with VARCHAR micro_niche_id FK
CREATE TABLE IF NOT EXISTS dynamic_demand (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    micro_niche_id VARCHAR(100) NOT NULL REFERENCES micro_niches(id) ON DELETE CASCADE,
    source VARCHAR(30) DEFAULT 'daily_wall',
    interaction_type VARCHAR(20) NOT NULL,
    strength FLOAT DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '14 days')
);

CREATE INDEX IF NOT EXISTS idx_dynamic_user ON dynamic_demand(user_id);
CREATE INDEX IF NOT EXISTS idx_dynamic_expires ON dynamic_demand(expires_at);

-- Recreate matches with VARCHAR micro_niche_id FK
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    micro_niche_id VARCHAR(100) REFERENCES micro_niches(id) ON DELETE SET NULL,
    batch_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'synced',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_a_id, user_b_id, batch_date)
);

CREATE INDEX IF NOT EXISTS idx_matches_user_a ON matches(user_a_id);
CREATE INDEX IF NOT EXISTS idx_matches_user_b ON matches(user_b_id);

-- Seed Categories with slug IDs
INSERT INTO categories (id, name, icon, sort_order) VALUES
('cat_01_fashion', 'Fashion & Apparel', 'shopping_bag', 1),
('cat_02_food', 'Food & Beverage', 'restaurant', 2),
('cat_03_tech', 'Tech & Gadgets', 'devices', 3),
('cat_04_beauty', 'Beauty & Personal Care', 'spa', 4),
('cat_05_health', 'Health & Wellness', 'health_and_safety', 5),
('cat_06_home', 'Home & Living', 'home', 6),
('cat_07_logistics', 'Logistics & Transport', 'local_shipping', 7),
('cat_08_pro_services', 'Professional Services', 'business_center', 8),
('cat_09_agriculture', 'Agriculture & Raw Materials', 'eco', 9),
('cat_10_education', 'Education & Training', 'school', 10),
('cat_11_media', 'Media & Entertainment', 'movie', 11),
('cat_12_construction', 'Construction & Real Estate', 'domain', 12)
ON CONFLICT (id) DO NOTHING;

-- Seed Micro-Niches with slug IDs
INSERT INTO micro_niches (id, category_id, name) VALUES
('mn_footwear', 'cat_01_fashion', 'Footwear'),
('mn_jewelry_watches', 'cat_01_fashion', 'Jewelry & Watches'),
('mn_mens_clothing', 'cat_01_fashion', 'Men''s Clothing'),
('mn_womens_clothing', 'cat_01_fashion', 'Women''s Clothing'),
('mn_bags_accessories', 'cat_01_fashion', 'Bags & Accessories'),
('mn_childrens_clothing', 'cat_01_fashion', 'Children''s Clothing'),
('mn_fabrics_textiles', 'cat_01_fashion', 'Fabrics & Textiles'),
('mn_packaged_foods', 'cat_02_food', 'Packaged Foods & Snacks'),
('mn_beverages_drinks', 'cat_02_food', 'Beverages & Drinks'),
('mn_catering_events', 'cat_02_food', 'Catering & Event Food'),
('mn_bakery_confectionery', 'cat_02_food', 'Bakery & Confectionery'),
('mn_fresh_produce', 'cat_02_food', 'Fresh Produce & Groceries'),
('mn_restaurant_fastfood', 'cat_02_food', 'Restaurant & Fast Food'),
('mn_smartphones_laptops', 'cat_03_tech', 'Smartphones & Laptops'),
('mn_tech_accessories', 'cat_03_tech', 'Tech Accessories'),
('mn_device_repairs', 'cat_03_tech', 'Device Repairs'),
('mn_software_saas', 'cat_03_tech', 'Software & SaaS'),
('mn_consumer_electronics', 'cat_03_tech', 'Consumer Electronics'),
('mn_networking_security', 'cat_03_tech', 'Networking & Security'),
('mn_skincare', 'cat_04_beauty', 'Skincare Products'),
('mn_haircare_wigs', 'cat_04_beauty', 'Hair Care & Wigs'),
('mn_makeup_cosmetics', 'cat_04_beauty', 'Makeup & Cosmetics'),
('mn_perfumes_fragrances', 'cat_04_beauty', 'Perfumes & Fragrances'),
('mn_salon_spa', 'cat_04_beauty', 'Salon & Spa Services'),
('mn_pharmacy_medicine', 'cat_05_health', 'Pharmacy & Medicine'),
('mn_fitness_gym', 'cat_05_health', 'Fitness & Gym'),
('mn_herbal_remedies', 'cat_05_health', 'Herbal & Natural Remedies'),
('mn_medical_equipment', 'cat_05_health', 'Medical Equipment'),
('mn_mental_health', 'cat_05_health', 'Mental Health & Coaching'),
('mn_furniture', 'cat_06_home', 'Furniture'),
('mn_interior_decor', 'cat_06_home', 'Interior Decor'),
('mn_kitchen_appliances', 'cat_06_home', 'Kitchen & Appliances'),
('mn_cleaning_supplies', 'cat_06_home', 'Cleaning Supplies'),
('mn_bedding_fabrics', 'cat_06_home', 'Bedding & Fabrics'),
('mn_last_mile_delivery', 'cat_07_logistics', 'Last-Mile Delivery'),
('mn_freight_haulage', 'cat_07_logistics', 'Freight & Haulage'),
('mn_warehousing_storage', 'cat_07_logistics', 'Warehousing & Storage'),
('mn_dispatch_courier', 'cat_07_logistics', 'Dispatch & Courier'),
('mn_vehicle_rentals', 'cat_07_logistics', 'Vehicle Rentals'),
('mn_accounting_bookkeeping', 'cat_08_pro_services', 'Accounting & Bookkeeping'),
('mn_legal_services', 'cat_08_pro_services', 'Legal Services'),
('mn_consulting_advisory', 'cat_08_pro_services', 'Consulting & Advisory'),
('mn_marketing_advertising', 'cat_08_pro_services', 'Marketing & Advertising'),
('mn_graphic_design', 'cat_08_pro_services', 'Graphic Design'),
('mn_web_app_dev', 'cat_08_pro_services', 'Web & App Development'),
('mn_photography_video', 'cat_08_pro_services', 'Photography & Videography'),
('mn_crop_farming', 'cat_09_agriculture', 'Crop Farming'),
('mn_livestock_poultry', 'cat_09_agriculture', 'Livestock & Poultry'),
('mn_fish_aquaculture', 'cat_09_agriculture', 'Fish & Aquaculture'),
('mn_agro_processing', 'cat_09_agriculture', 'Agro-Processing'),
('mn_farm_inputs', 'cat_09_agriculture', 'Farm Inputs & Equipment'),
('mn_tutoring_testprep', 'cat_10_education', 'Tutoring & Test Prep'),
('mn_pro_certification', 'cat_10_education', 'Professional Certification'),
('mn_online_courses', 'cat_10_education', 'Online Courses & E-Learning'),
('mn_vocational_training', 'cat_10_education', 'Vocational Training'),
('mn_school_supplies', 'cat_10_education', 'School Supplies & Books'),
('mn_music_production', 'cat_11_media', 'Music Production'),
('mn_event_planning', 'cat_11_media', 'Event Planning'),
('mn_content_creation', 'cat_11_media', 'Content Creation'),
('mn_printing_publishing', 'cat_11_media', 'Printing & Publishing'),
('mn_dj_sound', 'cat_11_media', 'DJ & Sound Equipment'),
('mn_building_materials', 'cat_12_construction', 'Building Materials'),
('mn_property_sales_rentals', 'cat_12_construction', 'Property Sales & Rentals'),
('mn_interior_finishing', 'cat_12_construction', 'Interior Finishing'),
('mn_plumbing_electrical', 'cat_12_construction', 'Plumbing & Electrical'),
('mn_architecture_drafting', 'cat_12_construction', 'Architecture & Drafting')
ON CONFLICT (id) DO NOTHING;
