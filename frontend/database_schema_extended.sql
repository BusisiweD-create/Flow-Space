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

-- Sample data removed for production use

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
