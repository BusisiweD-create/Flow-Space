-- Supabase Database Schema for Khonology App
-- Run these commands in your Supabase SQL editor

-- Enable Row Level Security
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  company TEXT NOT NULL,
  role TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create deliverables table
CREATE TABLE IF NOT EXISTS deliverables (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  definition_of_done TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft',
  assigned_to UUID REFERENCES profiles(id),
  created_by UUID REFERENCES profiles(id) NOT NULL,
  sprint_id UUID,
  priority TEXT DEFAULT 'medium',
  due_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sprints table
CREATE TABLE IF NOT EXISTS sprints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  planned_points INTEGER DEFAULT 0,
  completed_points INTEGER DEFAULT 0,
  status TEXT DEFAULT 'planning',
  created_by UUID REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sprint_deliverables junction table
CREATE TABLE IF NOT EXISTS sprint_deliverables (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
  deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(sprint_id, deliverable_id)
);

-- Create sign_offs table
CREATE TABLE IF NOT EXISTS sign_offs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
  signed_by UUID REFERENCES profiles(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  comments TEXT,
  signed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security Policies

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Deliverables policies
CREATE POLICY "Users can view all deliverables" ON deliverables
  FOR SELECT USING (true);

CREATE POLICY "Users can create deliverables" ON deliverables
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own deliverables" ON deliverables
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Users can delete own deliverables" ON deliverables
  FOR DELETE USING (auth.uid() = created_by);

-- Sprints policies
CREATE POLICY "Users can view all sprints" ON sprints
  FOR SELECT USING (true);

CREATE POLICY "Users can create sprints" ON sprints
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own sprints" ON sprints
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Users can delete own sprints" ON sprints
  FOR DELETE USING (auth.uid() = created_by);

-- Sprint deliverables policies
CREATE POLICY "Users can view sprint deliverables" ON sprint_deliverables
  FOR SELECT USING (true);

CREATE POLICY "Users can manage sprint deliverables" ON sprint_deliverables
  FOR ALL USING (true);

-- Sign-offs policies
CREATE POLICY "Users can view sign-offs" ON sign_offs
  FOR SELECT USING (true);

CREATE POLICY "Users can create sign-offs" ON sign_offs
  FOR INSERT WITH CHECK (auth.uid() = signed_by);

CREATE POLICY "Users can update own sign-offs" ON sign_offs
  FOR UPDATE USING (auth.uid() = signed_by);

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
