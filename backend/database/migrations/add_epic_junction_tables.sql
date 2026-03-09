-- Flow-Space Database Migration: Add Missing Epic Junction Tables
-- Run this script to add the missing sprint_epics and deliverable_epics junction tables

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
-- VERIFICATION QUERY
-- ============================================================
SELECT 'Epic junction tables migration completed successfully!' as status;

-- Verify tables were created
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_name IN ('sprint_epics', 'deliverable_epics')
ORDER BY table_name;
