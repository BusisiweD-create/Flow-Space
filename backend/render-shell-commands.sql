-- Render PostgreSQL Shell Commands
-- Copy and paste these commands in order in your Render psql shell

-- Step 2: Confirm current tables (optional - to see what exists)
\dt

-- Step 3: Create the complete epics table with all required columns
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

-- Step 4: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_epics_project ON epics(project_id);
CREATE INDEX IF NOT EXISTS idx_epics_status ON epics(status);
CREATE INDEX IF NOT EXISTS idx_epics_created_by ON epics(created_by);

-- Step 5: Create junction tables (needed for the backend code)
CREATE TABLE IF NOT EXISTS sprint_epics (
    id SERIAL PRIMARY KEY,
    sprint_id UUID NOT NULL REFERENCES sprints(id) ON DELETE CASCADE,
    epic_id UUID NOT NULL REFERENCES epics(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sprint_id, epic_id)
);

CREATE TABLE IF NOT EXISTS deliverable_epics (
    id SERIAL PRIMARY KEY,
    deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    epic_id UUID NOT NULL REFERENCES epics(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(deliverable_id, epic_id)
);

-- Create indexes for junction tables
CREATE INDEX IF NOT EXISTS idx_sprint_epics_sprint ON sprint_epics(sprint_id);
CREATE INDEX IF NOT EXISTS idx_sprint_epics_epic ON sprint_epics(epic_id);
CREATE INDEX IF NOT EXISTS idx_deliverable_epics_deliverable ON deliverable_epics(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_deliverable_epics_epic ON deliverable_epics(epic_id);

-- Step 6: Create trigger function for updated_at (if it doesn't exist)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to epics table
DROP TRIGGER IF EXISTS update_epics_updated_at ON epics;
CREATE TRIGGER update_epics_updated_at BEFORE UPDATE ON epics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 7: Verify tables were created
\dt epics
\dt sprint_epics  
\dt deliverable_epics

-- Step 8: Test the epics table (should return empty array)
SELECT COUNT(*) as epic_count FROM epics;
