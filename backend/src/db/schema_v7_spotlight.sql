-- Spotlight MVP 1.0 Schema Enhancements

ALTER TABLE spotlight_campaigns
ADD COLUMN IF NOT EXISTS submission_status VARCHAR(32) DEFAULT 'verified',
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS submission_requirement JSONB DEFAULT '{"prompt": "What are you sharing this cycle? Showcase your best product, offer, or service to the network.", "maxCharacters": 300, "placeholder": "e.g. 20% off all Men Wears this week with free delivery in Lagos..."}'::jsonb,
ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(128),
ADD COLUMN IF NOT EXISTS cycle_number INT DEFAULT 1;

-- Add index on idempotency_key
CREATE INDEX IF NOT EXISTS idx_spotlight_idempotency ON spotlight_campaigns(idempotency_key);
