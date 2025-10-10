-- =====================================================
-- DATABASE MIGRATIONS FOR DELIVERABLE & SPRINT SIGN-OFF HUB
-- =====================================================
-- This file contains incremental migrations for the database schema
-- Run these in order to set up the database step by step
-- =====================================================

-- =====================================================
-- MIGRATION 001: Initial Setup
-- =====================================================
-- Create basic tables for user management and projects

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    company VARCHAR(255),
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'project_manager', 'developer', 'client', 'stakeholder')),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    profile_image_url VARCHAR(500)
);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'on_hold', 'cancelled')),
    start_date DATE,
    end_date DATE,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MIGRATION 002: Sprint Management
-- =====================================================

-- Sprints table
CREATE TABLE IF NOT EXISTS sprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sprint metrics table
CREATE TABLE IF NOT EXISTS sprint_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sprint_id UUID NOT NULL REFERENCES sprints(id) ON DELETE CASCADE,
    committed_points INTEGER NOT NULL DEFAULT 0,
    completed_points INTEGER NOT NULL DEFAULT 0,
    carried_over_points INTEGER NOT NULL DEFAULT 0,
    test_pass_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    defects_opened INTEGER NOT NULL DEFAULT 0,
    defects_closed INTEGER NOT NULL DEFAULT 0,
    critical_defects INTEGER NOT NULL DEFAULT 0,
    high_defects INTEGER NOT NULL DEFAULT 0,
    medium_defects INTEGER NOT NULL DEFAULT 0,
    low_defects INTEGER NOT NULL DEFAULT 0,
    code_review_completion DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    documentation_status DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    risks TEXT,
    mitigations TEXT,
    scope_changes TEXT,
    uat_notes TEXT,
    recorded_by UUID NOT NULL REFERENCES users(id),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MIGRATION 003: Deliverable Management
-- =====================================================

-- Deliverables table
CREATE TABLE IF NOT EXISTS deliverables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'change_requested', 'rejected')),
    due_date DATE NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id),
    assigned_to UUID REFERENCES users(id),
    submitted_by UUID REFERENCES users(id),
    submitted_at TIMESTAMP,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Definition of Done items
CREATE TABLE IF NOT EXISTS deliverable_dod_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    item_text TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP,
    completed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Evidence links for deliverables
CREATE TABLE IF NOT EXISTS deliverable_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    link_url VARCHAR(500) NOT NULL,
    link_type VARCHAR(50) DEFAULT 'general' CHECK (link_type IN ('demo', 'repository', 'documentation', 'test_results', 'general')),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sprint-Deliverable relationships
CREATE TABLE IF NOT EXISTS deliverable_sprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    sprint_id UUID NOT NULL REFERENCES sprints(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(deliverable_id, sprint_id)
);

-- =====================================================
-- MIGRATION 004: Release Readiness Gate
-- =====================================================

-- Release readiness checks
CREATE TABLE IF NOT EXISTS release_readiness_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('green', 'amber', 'red')),
    internal_approver UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    approval_comment TEXT,
    checked_by UUID NOT NULL REFERENCES users(id),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Readiness items
CREATE TABLE IF NOT EXISTS readiness_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    readiness_check_id UUID NOT NULL REFERENCES release_readiness_checks(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    is_required BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    evidence TEXT,
    notes TEXT,
    is_acknowledged BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MIGRATION 005: Sign-Off Reports
-- =====================================================

-- Sign-off reports
CREATE TABLE IF NOT EXISTS sign_off_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    report_title VARCHAR(255) NOT NULL,
    report_content TEXT NOT NULL,
    sprint_performance_data JSONB,
    known_limitations TEXT,
    next_steps TEXT,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'under_review', 'approved', 'change_requested', 'rejected')),
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    submitted_by UUID REFERENCES users(id),
    submitted_at TIMESTAMP,
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    client_comment TEXT,
    change_request_details TEXT,
    digital_signature TEXT
);

-- Report-Sprint relationships
CREATE TABLE IF NOT EXISTS report_sprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    sprint_id UUID NOT NULL REFERENCES sprints(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(report_id, sprint_id)
);

-- =====================================================
-- MIGRATION 006: Client Review & Notifications
-- =====================================================

-- Client reviews
CREATE TABLE IF NOT EXISTS client_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(50) NOT NULL CHECK (action IN ('approve', 'change_request')),
    comment TEXT,
    change_request_details TEXT,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    reminder_date DATE,
    escalation_enabled BOOLEAN DEFAULT false,
    digital_signature TEXT,
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('review', 'change_request', 'report', 'metrics', 'reminder', 'approval')),
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    deliverable_id UUID REFERENCES deliverables(id),
    report_id UUID REFERENCES sign_off_reports(id),
    sprint_id UUID REFERENCES sprints(id),
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MIGRATION 007: Audit Trail & Additional Features
-- =====================================================

-- Activity logs
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Repository files
CREATE TABLE IF NOT EXISTS repository_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size BIGINT,
    content_hash VARCHAR(64),
    uploaded_by UUID NOT NULL REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Approval requests
CREATE TABLE IF NOT EXISTS approval_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    requested_by UUID NOT NULL REFERENCES users(id),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    comments TEXT
);

-- User sessions
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Project members
CREATE TABLE IF NOT EXISTS project_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('owner', 'manager', 'member', 'viewer')),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);

-- =====================================================
-- MIGRATION 008: Indexes for Performance
-- =====================================================

-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- Session indexes
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);

-- Project indexes
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects(created_by);

-- Sprint indexes
CREATE INDEX IF NOT EXISTS idx_sprints_project_id ON sprints(project_id);
CREATE INDEX IF NOT EXISTS idx_sprints_status ON sprints(status);
CREATE INDEX IF NOT EXISTS idx_sprints_dates ON sprints(start_date, end_date);

-- Sprint metrics indexes
CREATE INDEX IF NOT EXISTS idx_sprint_metrics_sprint_id ON sprint_metrics(sprint_id);
CREATE INDEX IF NOT EXISTS idx_sprint_metrics_recorded_at ON sprint_metrics(recorded_at);

-- Deliverable indexes
CREATE INDEX IF NOT EXISTS idx_deliverables_project_id ON deliverables(project_id);
CREATE INDEX IF NOT EXISTS idx_deliverables_status ON deliverables(status);
CREATE INDEX IF NOT EXISTS idx_deliverables_due_date ON deliverables(due_date);
CREATE INDEX IF NOT EXISTS idx_deliverables_created_by ON deliverables(created_by);

-- Report indexes
CREATE INDEX IF NOT EXISTS idx_sign_off_reports_deliverable_id ON sign_off_reports(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_sign_off_reports_status ON sign_off_reports(status);
CREATE INDEX IF NOT EXISTS idx_sign_off_reports_created_by ON sign_off_reports(created_by);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Activity log indexes
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);

-- =====================================================
-- MIGRATION 009: Triggers and Functions
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sprints_updated_at ON sprints;
CREATE TRIGGER update_sprints_updated_at BEFORE UPDATE ON sprints FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sprint_metrics_updated_at ON sprint_metrics;
CREATE TRIGGER update_sprint_metrics_updated_at BEFORE UPDATE ON sprint_metrics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_deliverables_updated_at ON deliverables;
CREATE TRIGGER update_deliverables_updated_at BEFORE UPDATE ON deliverables FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- MIGRATION 010: Views for Common Queries
-- =====================================================

-- View for deliverable summary
CREATE OR REPLACE VIEW deliverable_summary AS
SELECT 
    d.id,
    d.title,
    d.description,
    d.status,
    d.due_date,
    d.created_at,
    u.first_name || ' ' || u.last_name as created_by_name,
    COUNT(DISTINCT ds.sprint_id) as sprint_count,
    COUNT(DISTINCT dod.id) as dod_items_count,
    COUNT(DISTINCT de.id) as evidence_count
FROM deliverables d
LEFT JOIN users u ON d.created_by = u.id
LEFT JOIN deliverable_sprints ds ON d.id = ds.deliverable_id
LEFT JOIN deliverable_dod_items dod ON d.id = dod.deliverable_id
LEFT JOIN deliverable_evidence de ON d.id = de.deliverable_id
GROUP BY d.id, d.title, d.description, d.status, d.due_date, d.created_at, u.first_name, u.last_name;

-- View for sprint performance summary
CREATE OR REPLACE VIEW sprint_performance_summary AS
SELECT 
    s.id,
    s.name,
    s.start_date,
    s.end_date,
    s.status,
    sm.committed_points,
    sm.completed_points,
    sm.test_pass_rate,
    sm.defects_opened,
    sm.defects_closed,
    CASE 
        WHEN sm.test_pass_rate >= 95 AND sm.defects_opened - sm.defects_closed <= 2 THEN 'Excellent'
        WHEN sm.test_pass_rate >= 90 AND sm.defects_opened - sm.defects_closed <= 5 THEN 'Good'
        ELSE 'Needs Attention'
    END as quality_status_text,
    u.first_name || ' ' || u.last_name as recorded_by_name
FROM sprints s
LEFT JOIN sprint_metrics sm ON s.id = sm.sprint_id
LEFT JOIN users u ON sm.recorded_by = u.id;

-- View for notification summary
CREATE OR REPLACE VIEW notification_summary AS
SELECT 
    n.id,
    n.title,
    n.message,
    n.type,
    n.priority,
    n.is_read,
    n.created_at,
    u.first_name || ' ' || u.last_name as user_name
FROM notifications n
JOIN users u ON n.user_id = u.id
ORDER BY n.created_at DESC;

-- =====================================================
-- END OF MIGRATIONS
-- =====================================================
