-- Extended Database Schema for Flow-Space Deliverable & Sprint Sign-Off Hub
-- This includes all tables needed for the complete use case

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS sign_offs CASCADE;
DROP TABLE IF EXISTS sign_off_reports CASCADE;
DROP TABLE IF EXISTS client_reviews CASCADE;
DROP TABLE IF EXISTS release_readiness_checks CASCADE;
DROP TABLE IF EXISTS deliverable_evidence CASCADE;
DROP TABLE IF EXISTS sprint_metrics CASCADE;
DROP TABLE IF EXISTS sprint_deliverables CASCADE;
DROP TABLE IF EXISTS deliverables CASCADE;
DROP TABLE IF EXISTS sprints CASCADE;
DROP TABLE IF EXISTS email_verification_tokens CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Create profiles table (users)
CREATE TABLE IF NOT EXISTS profiles (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'manager', 'user', 'client')),
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sprints table
CREATE TABLE IF NOT EXISTS sprints (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  planned_points INTEGER DEFAULT 0,
  completed_points INTEGER DEFAULT 0,
  status TEXT DEFAULT 'planning' CHECK (status IN ('planning', 'in_progress', 'completed', 'cancelled')),
  created_by TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create deliverables table
CREATE TABLE IF NOT EXISTS deliverables (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  definition_of_done TEXT NOT NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'review', 'submitted', 'approved', 'change_requested', 'completed')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  due_date DATE,
  evidence_links TEXT, -- JSON array of links
  assigned_to TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  created_by TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sprint_deliverables junction table
CREATE TABLE IF NOT EXISTS sprint_deliverables (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  sprint_id TEXT REFERENCES sprints(id) ON DELETE CASCADE,
  deliverable_id TEXT REFERENCES deliverables(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(sprint_id, deliverable_id)
);

-- Create sprint_metrics table for detailed sprint performance data
CREATE TABLE IF NOT EXISTS sprint_metrics (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  sprint_id TEXT REFERENCES sprints(id) ON DELETE CASCADE,
  metric_type TEXT NOT NULL CHECK (metric_type IN ('velocity', 'burndown', 'burnup', 'defects', 'test_pass_rate', 'coverage', 'scope_change')),
  metric_value DECIMAL(10,2) NOT NULL,
  metric_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create deliverable_evidence table for detailed evidence tracking
CREATE TABLE IF NOT EXISTS deliverable_evidence (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  deliverable_id TEXT REFERENCES deliverables(id) ON DELETE CASCADE,
  evidence_type TEXT NOT NULL CHECK (evidence_type IN ('demo_link', 'repository', 'test_summary', 'user_guide', 'documentation', 'screenshot', 'video')),
  title TEXT NOT NULL,
  url TEXT,
  file_path TEXT,
  description TEXT,
  uploaded_by TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sign_off_reports table
CREATE TABLE IF NOT EXISTS sign_off_reports (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  deliverable_id TEXT REFERENCES deliverables(id) ON DELETE CASCADE,
  report_title TEXT NOT NULL,
  report_content TEXT NOT NULL, -- JSON content of the report
  sprint_performance_data TEXT, -- JSON data for charts
  known_limitations TEXT,
  next_steps TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'ready_for_review', 'under_review', 'approved', 'change_requested')),
  created_by TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create client_reviews table
CREATE TABLE IF NOT EXISTS client_reviews (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  sign_off_report_id TEXT REFERENCES sign_off_reports(id) ON DELETE CASCADE,
  reviewer_id TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  review_status TEXT NOT NULL CHECK (review_status IN ('pending', 'approved', 'change_requested')),
  review_comments TEXT,
  change_request_details TEXT,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sign_offs table for final approvals
CREATE TABLE IF NOT EXISTS sign_offs (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  deliverable_id TEXT REFERENCES deliverables(id) ON DELETE CASCADE,
  sign_off_report_id TEXT REFERENCES sign_off_reports(id) ON DELETE CASCADE,
  client_review_id TEXT REFERENCES client_reviews(id) ON DELETE CASCADE,
  signed_by TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  signature_data TEXT, -- Digital signature data
  signed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address TEXT,
  user_agent TEXT
);

-- Create release_readiness_checks table
CREATE TABLE IF NOT EXISTS release_readiness_checks (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  deliverable_id TEXT REFERENCES deliverables(id) ON DELETE CASCADE,
  check_type TEXT NOT NULL CHECK (check_type IN ('dod_complete', 'evidence_attached', 'sprint_outcomes', 'test_evidence', 'documentation', 'security_audit')),
  check_name TEXT NOT NULL,
  is_required BOOLEAN DEFAULT TRUE,
  is_passed BOOLEAN DEFAULT FALSE,
  check_details TEXT,
  checked_by TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  checked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create email_verification_tokens table
CREATE TABLE IF NOT EXISTS email_verification_tokens (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  user_id TEXT REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  user_id TEXT REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('welcome', 'deliverable_assigned', 'sprint_update', 'sign_off_requested', 'sign_off_approved', 'change_requested', 'reminder')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  related_entity_type TEXT, -- 'deliverable', 'sprint', 'sign_off_report'
  related_entity_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audit_log table
CREATE TABLE IF NOT EXISTS audit_log (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  user_id TEXT REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  old_value JSONB,
  new_value JSONB,
  ip_address TEXT,
  user_agent TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sprints_updated_at BEFORE UPDATE ON sprints FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_deliverables_updated_at BEFORE UPDATE ON deliverables FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sign_off_reports_updated_at BEFORE UPDATE ON sign_off_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO profiles (id, email, password_hash, first_name, last_name, role, is_verified) VALUES
('00000000-0000-0000-0000-000000000001', 'john@acme.com', '$2b$10$rQZ8k8QZ8k8QZ8k8QZ8k8O', 'John', 'Doe', 'manager', true),
('00000000-0000-0000-0000-000000000002', 'jane@acme.com', '$2b$10$rQZ8k8QZ8k8QZ8k8QZ8k8O', 'Jane', 'Smith', 'user', true),
('00000000-0000-0000-0000-000000000003', 'client@acme.com', '$2b$10$rQZ8k8QZ8k8QZ8k8QZ8k8O', 'Client', 'User', 'client', true);

INSERT INTO sprints (id, name, description, start_date, end_date, planned_points, completed_points, status, created_by) VALUES
('sprint-001', 'Sprint 1 - Auth Foundation', 'User authentication and basic security features', '2024-01-01', '2024-01-14', 21, 18, 'completed', '00000000-0000-0000-0000-000000000001'),
('sprint-002', 'Sprint 2 - Auth Enhancement', 'Advanced authentication features and security hardening', '2024-01-15', '2024-01-28', 19, 19, 'completed', '00000000-0000-0000-0000-000000000001'),
('sprint-003', 'Sprint 3 - Payment Integration', 'Stripe payment gateway integration', '2024-01-29', '2024-02-11', 25, 12, 'in_progress', '00000000-0000-0000-0000-000000000001');

INSERT INTO deliverables (id, title, description, definition_of_done, status, priority, due_date, assigned_to, created_by) VALUES
('deliverable-001', 'User Authentication System', 'Complete user login, registration, and role-based access control', 'All unit tests pass, Code review completed, Security audit passed, Documentation updated', 'submitted', 'high', '2024-02-15', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'),
('deliverable-002', 'Payment Integration', 'Stripe payment gateway integration with subscription management', 'Payment flow tested, PCI compliance verified, Error handling implemented, User documentation created', 'draft', 'high', '2024-02-28', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'),
('deliverable-003', 'Mobile App Release', 'iOS and Android app store deployment', 'App store approval received, Performance testing completed, User acceptance testing passed, Release notes published', 'approved', 'critical', '2024-01-31', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001');

INSERT INTO sprint_deliverables (sprint_id, deliverable_id) VALUES
('sprint-001', 'deliverable-001'),
('sprint-002', 'deliverable-001'),
('sprint-003', 'deliverable-002');

INSERT INTO sprint_metrics (sprint_id, metric_type, metric_value, metric_date) VALUES
('sprint-001', 'velocity', 18.0, '2024-01-14'),
('sprint-001', 'test_pass_rate', 95.5, '2024-01-14'),
('sprint-001', 'defects', 3.0, '2024-01-14'),
('sprint-002', 'velocity', 19.0, '2024-01-28'),
('sprint-002', 'test_pass_rate', 98.2, '2024-01-28'),
('sprint-002', 'defects', 1.0, '2024-01-28'),
('sprint-003', 'velocity', 12.0, '2024-02-05'),
('sprint-003', 'test_pass_rate', 92.1, '2024-02-05'),
('sprint-003', 'defects', 2.0, '2024-02-05');

INSERT INTO deliverable_evidence (deliverable_id, evidence_type, title, url, description, uploaded_by) VALUES
('deliverable-001', 'demo_link', 'Authentication Demo', 'https://demo.acme.com/auth', 'Live demonstration of authentication features', '00000000-0000-0000-0000-000000000002'),
('deliverable-001', 'repository', 'Auth Module Repository', 'https://github.com/acme/auth-module', 'Source code repository for authentication module', '00000000-0000-0000-0000-000000000002'),
('deliverable-001', 'test_summary', 'Test Results Summary', 'https://reports.acme.com/auth-tests', 'Comprehensive test results and coverage report', '00000000-0000-0000-0000-000000000002'),
('deliverable-002', 'demo_link', 'Payment Demo', 'https://demo.acme.com/payment', 'Live demonstration of payment integration', '00000000-0000-0000-0000-000000000002');

INSERT INTO sign_off_reports (id, deliverable_id, report_title, report_content, sprint_performance_data, status, created_by) VALUES
('report-001', 'deliverable-001', 'User Authentication System - Sign-Off Report', '{"sections": ["Executive Summary", "Deliverable Overview", "Sprint Performance", "Quality Metrics", "Evidence Attached"]}', '{"velocity_trend": [18, 19], "test_pass_rates": [95.5, 98.2], "defect_counts": [3, 1]}', 'ready_for_review', '00000000-0000-0000-0000-000000000001');

INSERT INTO client_reviews (sign_off_report_id, reviewer_id, review_status, review_comments, reviewed_at) VALUES
('report-001', '00000000-0000-0000-0000-000000000003', 'pending', NULL, NULL);

INSERT INTO release_readiness_checks (deliverable_id, check_type, check_name, is_required, is_passed, checked_by, checked_at) VALUES
('deliverable-001', 'dod_complete', 'Definition of Done Complete', true, true, '00000000-0000-0000-0000-000000000001', NOW()),
('deliverable-001', 'evidence_attached', 'Evidence Attached', true, true, '00000000-0000-0000-0000-000000000001', NOW()),
('deliverable-001', 'sprint_outcomes', 'Sprint Outcomes Documented', true, true, '00000000-0000-0000-0000-000000000001', NOW()),
('deliverable-001', 'test_evidence', 'Test Evidence Provided', true, true, '00000000-0000-0000-0000-000000000001', NOW()),
('deliverable-002', 'dod_complete', 'Definition of Done Complete', true, false, NULL, NULL),
('deliverable-002', 'evidence_attached', 'Evidence Attached', true, false, NULL, NULL);

INSERT INTO notifications (user_id, type, title, message, related_entity_type, related_entity_id) VALUES
('00000000-0000-0000-0000-000000000003', 'sign_off_requested', 'Sign-Off Request', 'A new deliverable is ready for your review: User Authentication System', 'deliverable', 'deliverable-001'),
('00000000-0000-0000-0000-000000000002', 'deliverable_assigned', 'Deliverable Assigned', 'You have been assigned to work on: Payment Integration', 'deliverable', 'deliverable-002');

-- Create indexes for better performance
CREATE INDEX idx_sprints_status ON sprints(status);
CREATE INDEX idx_deliverables_status ON deliverables(status);
CREATE INDEX idx_deliverables_assigned_to ON deliverables(assigned_to);
CREATE INDEX idx_sprint_metrics_sprint_id ON sprint_metrics(sprint_id);
CREATE INDEX idx_deliverable_evidence_deliverable_id ON deliverable_evidence(deliverable_id);
CREATE INDEX idx_sign_off_reports_deliverable_id ON sign_off_reports(deliverable_id);
CREATE INDEX idx_client_reviews_report_id ON client_reviews(sign_off_report_id);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
