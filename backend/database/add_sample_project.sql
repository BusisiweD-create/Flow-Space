-- Add a sample project that will be visible to all users
-- This uses the actual users in your database

-- Get the first user ID (delivery lead)
DO $$
DECLARE
  user_id_val UUID;
BEGIN
  -- Get any existing user ID
  SELECT id INTO user_id_val FROM users LIMIT 1;
  
  -- Insert sample project
  INSERT INTO projects (id, name, key, description, project_type, created_by, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'Sample Project',
    'SAMPLE',
    'This is a sample project for testing',
    'agile',
    user_id_val,
    NOW(),
    NOW()
  )
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Sample project created successfully';
END $$;

-- Verify projects
SELECT id, name, key, description, created_by FROM projects;

