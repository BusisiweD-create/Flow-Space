-- Flow-Space Database Migration: Add Tickets Table
-- Run this script to add the missing tickets table for sprint management

-- ============================================================
-- TICKETS TABLE (for sprint task management)
-- ============================================================
CREATE TABLE IF NOT EXISTS tickets (
    ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_key VARCHAR(50) UNIQUE NOT NULL,
    summary VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'To Do',
    issue_type VARCHAR(50) DEFAULT 'Task',
    priority VARCHAR(20) DEFAULT 'Medium',
    assignee VARCHAR(255), -- Email of assigned user
    reporter VARCHAR(255) NOT NULL, -- Email of reporter
    sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for tickets
CREATE INDEX IF NOT EXISTS idx_tickets_sprint ON tickets(sprint_id);
CREATE INDEX IF NOT EXISTS idx_tickets_project ON tickets(project_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_assignee ON tickets(assignee);
CREATE INDEX IF NOT EXISTS idx_tickets_reporter ON tickets(reporter);

-- Insert default ticket types if not exist
INSERT INTO ticket_types (name, description, icon, color) VALUES
    ('Task', 'General task or work item', 'task', '#28A745'),
    ('Bug', 'Software bug or issue', 'bug', '#DC3545'),
    ('Story', 'User story or feature', 'story', '#007ACC'),
    ('Epic', 'Large feature or initiative', 'epic', '#6F42C1'),
    ('Improvement', 'Enhancement to existing feature', 'improvement', '#FF9800')
ON CONFLICT (name) DO NOTHING;

SELECT 'Tickets table migration completed successfully!' as status;
