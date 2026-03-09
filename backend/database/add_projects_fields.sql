-- Add missing fields to projects table for our new features
-- Run this once to update the existing table

ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE,
ADD COLUMN IF NOT EXISTS client VARCHAR(255),
ADD COLUMN IF NOT EXISTS type VARCHAR(100);

-- Add comment for documentation
COMMENT ON COLUMN projects.start_date IS 'Project start date';
COMMENT ON COLUMN projects.end_date IS 'Project end date';
COMMENT ON COLUMN projects.client IS 'Client name or company';
COMMENT ON COLUMN projects.type IS 'Project type (e.g., web, mobile, internal)';
