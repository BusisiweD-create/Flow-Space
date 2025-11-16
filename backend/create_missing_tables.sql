-- ============================================
-- Flow-Space: Create Missing Tables and Columns
-- ============================================

-- 1. Create tickets table
CREATE TABLE IF NOT EXISTS tickets (
    ticket_id TEXT PRIMARY KEY,
    ticket_key TEXT UNIQUE NOT NULL,
    summary TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'To Do' CHECK (status IN ('To Do', 'In Progress', 'Done', 'Blocked')),
    issue_type TEXT DEFAULT 'Task' CHECK (issue_type IN ('Task', 'Bug', 'Story', 'Epic', 'Subtask')),
    priority TEXT DEFAULT 'Medium' CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
    assignee TEXT,
    reporter TEXT,
    sprint_id TEXT,
    project_id TEXT,
    user_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create activity_log table
CREATE TABLE IF NOT EXISTS activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_title VARCHAR(255) NOT NULL,
    activity_description TEXT,
    deliverable_id TEXT,
    sprint_id TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Update projects table - add missing columns
ALTER TABLE projects ADD COLUMN IF NOT EXISTS key TEXT UNIQUE;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS project_type TEXT DEFAULT 'software';
ALTER TABLE projects ADD COLUMN IF NOT EXISTS created_by TEXT;

-- 4. Update notifications table - add enhanced columns
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS created_by TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS deliverable_id TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS sprint_id TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS action_url TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS metadata JSONB;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 5. Update deliverables table - add missing columns
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS progress DECIMAL(5,2) DEFAULT 0.00 CHECK (progress >= 0 AND progress <= 100);
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS sprint_id TEXT;
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'Medium';

-- 6. Ensure sprints table has created_by (if using TEXT/UUID)
-- Check if sprints.created_by exists and is correct type
-- If using TEXT in server.js, ensure compatibility

-- 7. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tickets_sprint_id ON tickets(sprint_id);
CREATE INDEX IF NOT EXISTS idx_tickets_project_id ON tickets(project_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_assignee ON tickets(assignee);
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id);

CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_deliverable_id ON activity_log(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON activity_log(created_at);

CREATE INDEX IF NOT EXISTS idx_projects_key ON projects(key);
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects(created_by);

CREATE INDEX IF NOT EXISTS idx_notifications_deliverable_id ON notifications(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sprint_id ON notifications(sprint_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_by ON notifications(created_by);

CREATE INDEX IF NOT EXISTS idx_deliverables_sprint_id ON deliverables(sprint_id);
CREATE INDEX IF NOT EXISTS idx_deliverables_progress ON deliverables(progress);

-- 8. Create updated_at trigger function (if not exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Apply updated_at triggers
DROP TRIGGER IF EXISTS update_tickets_updated_at ON tickets;
CREATE TRIGGER update_tickets_updated_at 
    BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications;
CREATE TRIGGER update_notifications_updated_at 
    BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 10. Add foreign key constraints (optional, can be added later if needed)
-- Note: These are commented out since IDs might be TEXT or UUID depending on your setup
-- ALTER TABLE tickets ADD CONSTRAINT fk_tickets_sprint FOREIGN KEY (sprint_id) REFERENCES sprints(id);
-- ALTER TABLE tickets ADD CONSTRAINT fk_tickets_project FOREIGN KEY (project_id) REFERENCES projects(id);
-- ALTER TABLE tickets ADD CONSTRAINT fk_tickets_user FOREIGN KEY (user_id) REFERENCES users(id);
-- ALTER TABLE activity_log ADD CONSTRAINT fk_activity_log_user FOREIGN KEY (user_id) REFERENCES users(id);
-- ALTER TABLE deliverables ADD CONSTRAINT fk_deliverables_sprint FOREIGN KEY (sprint_id) REFERENCES sprints(id);
-- ALTER TABLE notifications ADD CONSTRAINT fk_notifications_deliverable FOREIGN KEY (deliverable_id) REFERENCES deliverables(id);
-- ALTER TABLE notifications ADD CONSTRAINT fk_notifications_sprint FOREIGN KEY (sprint_id) REFERENCES sprints(id);

-- ============================================
-- Verification queries (run these to check)
-- ============================================
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('tickets', 'activity_log');
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'projects' AND column_name IN ('key', 'project_type', 'created_by');
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'notifications' AND column_name IN ('created_by', 'deliverable_id', 'sprint_id', 'priority', 'action_url', 'metadata', 'updated_at');
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'deliverables' AND column_name IN ('progress', 'sprint_id', 'priority');