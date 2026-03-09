-- Production Database Migration: Add Missing Epics Tables
-- Run this script on the production database (Render) to fix epics functionality

-- ============================================================
-- EPICS TABLE (for grouping deliverables across sprints)
-- ============================================================
CREATE TABLE IF NOT EXISTS epics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'draft',
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    sprint_ids UUID[] DEFAULT '{}',
    deliverable_ids UUID[] DEFAULT '{}',
    start_date TIMESTAMP,
    target_date TIMESTAMP,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for epics
CREATE INDEX IF NOT EXISTS idx_epics_project ON epics(project_id);
CREATE INDEX IF NOT EXISTS idx_epics_status ON epics(status);
CREATE INDEX IF NOT EXISTS idx_epics_created_by ON epics(created_by);

-- ============================================================
-- SPRINT_EPICS JUNCTION TABLE (many-to-many relationship)
-- ============================================================
CREATE TABLE IF NOT EXISTS sprint_epics (
    id SERIAL PRIMARY KEY,
    sprint_id UUID NOT NULL REFERENCES sprints(id) ON DELETE CASCADE,
    epic_id UUID NOT NULL REFERENCES epics(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sprint_id, epic_id)
);

-- Create indexes for sprint_epics
CREATE INDEX IF NOT EXISTS idx_sprint_epics_sprint ON sprint_epics(sprint_id);
CREATE INDEX IF NOT EXISTS idx_sprint_epics_epic ON sprint_epics(epic_id);

-- ============================================================
-- DELIVERABLE_EPICS JUNCTION TABLE (many-to-many relationship)
-- ============================================================
CREATE TABLE IF NOT EXISTS deliverable_epics (
    id SERIAL PRIMARY KEY,
    deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    epic_id UUID NOT NULL REFERENCES epics(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(deliverable_id, epic_id)
);

-- Create indexes for deliverable_epics
CREATE INDEX IF NOT EXISTS idx_deliverable_epics_deliverable ON deliverable_epics(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_deliverable_epics_epic ON deliverable_epics(epic_id);

-- ============================================================
-- TRIGGER FOR EPICS UPDATED_AT
-- ============================================================
-- Create trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger for epics
DROP TRIGGER IF EXISTS update_epics_updated_at ON epics;
CREATE TRIGGER update_epics_updated_at BEFORE UPDATE ON epics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT 'Production epics migration completed successfully!' as status;

-- Verify tables were created
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_name IN ('epics', 'sprint_epics', 'deliverable_epics')
ORDER BY table_name;
