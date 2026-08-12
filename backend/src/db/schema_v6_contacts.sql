-- ==============================================================================
-- BIZSQUARE SCHEMA V6: CONTACT MANAGEMENT, LABELS & SYNC ENHANCEMENTS
-- ==============================================================================

-- 1. ADD STARRED & ARCHIVED TO USER CONTACTS
ALTER TABLE user_contacts 
ADD COLUMN IF NOT EXISTS is_starred BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_uc_starred ON user_contacts(owner_id, is_starred);
CREATE INDEX IF NOT EXISTS idx_uc_archived ON user_contacts(owner_id, is_archived);

-- 2. CONTACT LABELS
CREATE TABLE IF NOT EXISTS contact_labels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(60) NOT NULL,
    color VARCHAR(30) DEFAULT '#0058FF',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_contact_label UNIQUE (user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_cl_user ON contact_labels(user_id);

-- 3. CONTACT LABEL ASSIGNMENTS
CREATE TABLE IF NOT EXISTS contact_label_assignments (
    contact_id UUID NOT NULL REFERENCES user_contacts(id) ON DELETE CASCADE,
    label_id UUID NOT NULL REFERENCES contact_labels(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (contact_id, label_id)
);

CREATE INDEX IF NOT EXISTS idx_cla_label ON contact_label_assignments(label_id);
