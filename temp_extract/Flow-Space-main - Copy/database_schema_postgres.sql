-- PostgreSQL Database Schema for Flow-Space App
-- Run these commands in pgAdmin or psql

-- Create profiles table with password authentication
CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  company TEXT NOT NULL,
  role TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create deliverables table
CREATE TABLE IF NOT EXISTS deliverables (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  definition_of_done TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft',
  assigned_to TEXT REFERENCES profiles(id),
  created_by TEXT REFERENCES profiles(id) NOT NULL,
  sprint_id TEXT,
  priority TEXT DEFAULT 'medium',
  due_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sprints table
CREATE TABLE IF NOT EXISTS sprints (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  planned_points INTEGER DEFAULT 0,
  completed_points INTEGER DEFAULT 0,
  status TEXT DEFAULT 'planning',
  created_by TEXT REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sprint_deliverables junction table
CREATE TABLE IF NOT EXISTS sprint_deliverables (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  sprint_id TEXT REFERENCES sprints(id) ON DELETE CASCADE,
  deliverable_id TEXT REFERENCES deliverables(id) ON DELETE CASCADE,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(sprint_id, deliverable_id)
);

-- Create sign_offs table
CREATE TABLE IF NOT EXISTS sign_offs (
  id TEXT DEFAULT gen_random_uuid()::TEXT PRIMARY KEY,
  deliverable_id TEXT REFERENCES deliverables(id) ON DELETE CASCADE,
  signed_by TEXT REFERENCES profiles(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  comments TEXT,
  signed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Functions and triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deliverables_updated_at BEFORE UPDATE ON deliverables
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sprints_updated_at BEFORE UPDATE ON sprints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample data (optional)
INSERT INTO profiles (id, first_name, last_name, company, role, email, password_hash) VALUES
  ('00000000-0000-0000-0000-000000000001', 'John', 'Doe', 'Acme Corp', 'Project Manager', 'john@acme.com', '123456'),
  ('00000000-0000-0000-0000-000000000002', 'Jane', 'Smith', 'Acme Corp', 'Developer', 'jane@acme.com', '123456')
ON CONFLICT (id) DO NOTHING;
