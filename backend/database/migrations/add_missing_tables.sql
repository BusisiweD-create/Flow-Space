-- Flow-Space Database Migration: Add Missing Tables
-- Run this script to add all missing tables for the Deliverable & Sprint Sign-Off Hub

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
-- SPRINT METRICS TABLE (detailed sprint performance data)
-- ============================================================
CREATE TABLE IF NOT EXISTS sprint_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
    planned_points INTEGER DEFAULT 0,
    completed_points INTEGER DEFAULT 0,
    velocity DECIMAL(5,2) DEFAULT 0,
    test_pass_rate DECIMAL(5,2) DEFAULT 0,
    defect_count INTEGER DEFAULT 0,
    uat_notes TEXT,
    quality_score DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sprint_id)
);

CREATE INDEX IF NOT EXISTS idx_sprint_metrics_sprint ON sprint_metrics(sprint_id);

-- ============================================================
-- DIGITAL SIGNATURES TABLE (for sign-off approvals)
-- ============================================================
CREATE TABLE IF NOT EXISTS digital_signatures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    signature_data TEXT, -- Base64 encoded signature image
    signed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_signatures_report ON digital_signatures(report_id);
CREATE INDEX IF NOT EXISTS idx_signatures_user ON digital_signatures(user_id);

-- ============================================================
-- APPROVAL REQUESTS TABLE (for internal/client approvals)
-- ============================================================
CREATE TABLE IF NOT EXISTS approval_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
    report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    requester_id UUID REFERENCES users(id) ON DELETE SET NULL,
    approver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'pending',
    approval_type VARCHAR(50) DEFAULT 'internal', -- internal, client
    comments TEXT,
    evidence_links JSONB DEFAULT '[]',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_approval_requests_deliverable ON approval_requests(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON approval_requests(status);
CREATE INDEX IF NOT EXISTS idx_approval_requests_approver ON approval_requests(approver_id);

-- ============================================================
-- CHANGE REQUESTS TABLE (for client change requests)
-- ============================================================
CREATE TABLE IF NOT EXISTS change_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    requested_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'open', -- open, in_progress, resolved, rejected
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high, critical
    resolution TEXT,
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_change_requests_report ON change_requests(report_id);
CREATE INDEX IF NOT EXISTS idx_change_requests_status ON change_requests(status);

-- ============================================================
-- DOCUMENTS/REPOSITORY TABLE (for file storage)
-- ============================================================
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL,
    file_type VARCHAR(100),
    file_size BIGINT,
    mime_type VARCHAR(100),
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    deliverable_id UUID REFERENCES deliverables(id) ON DELETE SET NULL,
    sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
    uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
    tags TEXT[] DEFAULT '{}',
    version INTEGER DEFAULT 1,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_documents_project ON documents(project_id);
CREATE INDEX IF NOT EXISTS idx_documents_deliverable ON documents(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON documents(uploaded_by);

-- ============================================================
-- ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================================

-- Add columns to deliverables table
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'Medium';
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL;
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS sprint_ids UUID[] DEFAULT '{}';
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS epic_id UUID REFERENCES epics(id) ON DELETE SET NULL;
ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS evidence_links JSONB DEFAULT '[]';

-- Add columns to sign_off_reports table
ALTER TABLE sign_off_reports ADD COLUMN IF NOT EXISTS report_title VARCHAR(255);
ALTER TABLE sign_off_reports ADD COLUMN IF NOT EXISTS sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL;
ALTER TABLE sign_off_reports ADD COLUMN IF NOT EXISTS known_limitations TEXT;
ALTER TABLE sign_off_reports ADD COLUMN IF NOT EXISTS next_steps TEXT;
ALTER TABLE sign_off_reports ADD COLUMN IF NOT EXISTS reviewer_comments JSONB DEFAULT '[]';

-- Add columns to notifications table
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add columns to sprints table
ALTER TABLE sprints ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE sprints ADD COLUMN IF NOT EXISTS goals TEXT;
ALTER TABLE sprints ADD COLUMN IF NOT EXISTS uat_notes TEXT;

-- ============================================================
-- CREATE TRIGGERS FOR NEW TABLES
-- ============================================================

-- Trigger for epics
DROP TRIGGER IF EXISTS update_epics_updated_at ON epics;
CREATE TRIGGER update_epics_updated_at BEFORE UPDATE ON epics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for sprint_metrics
DROP TRIGGER IF EXISTS update_sprint_metrics_updated_at ON sprint_metrics;
CREATE TRIGGER update_sprint_metrics_updated_at BEFORE UPDATE ON sprint_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for approval_requests
DROP TRIGGER IF EXISTS update_approval_requests_updated_at ON approval_requests;
CREATE TRIGGER update_approval_requests_updated_at BEFORE UPDATE ON approval_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for change_requests
DROP TRIGGER IF EXISTS update_change_requests_updated_at ON change_requests;
CREATE TRIGGER update_change_requests_updated_at BEFORE UPDATE ON change_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for documents
DROP TRIGGER IF EXISTS update_documents_updated_at ON documents;
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ADD SCOPE CHANGE COLUMNS TO SPRINT_METRICS
-- ============================================================
ALTER TABLE sprint_metrics ADD COLUMN IF NOT EXISTS points_added_during_sprint INTEGER DEFAULT 0;
ALTER TABLE sprint_metrics ADD COLUMN IF NOT EXISTS points_removed_during_sprint INTEGER DEFAULT 0;
ALTER TABLE sprint_metrics ADD COLUMN IF NOT EXISTS scope_changes TEXT;
ALTER TABLE sprint_metrics ADD COLUMN IF NOT EXISTS blockers TEXT;
ALTER TABLE sprint_metrics ADD COLUMN IF NOT EXISTS decisions TEXT;

-- ============================================================
-- INSERT DEFAULT DATA
-- ============================================================

-- Insert default user roles if not exist
INSERT INTO user_roles (name, display_name, description, color, icon)
VALUES 
    ('systemAdmin', 'System Admin', 'Full system access and configuration', '#FF0000', 'admin_panel_settings'),
    ('deliveryLead', 'Delivery Lead', 'Manages deliverables and team', '#0077B6', 'supervisor_account'),
    ('teamMember', 'Team Member', 'Works on deliverables', '#28A745', 'person'),
    ('clientReviewer', 'Client Reviewer', 'Reviews and approves deliverables', '#FFC107', 'rate_review')
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- VERIFICATION QUERY
-- ============================================================
-- Run this to verify all tables exist:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

SELECT 'Migration completed successfully!' as status;
