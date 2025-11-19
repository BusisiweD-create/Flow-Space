-- Setup script for shared PostgreSQL database
-- Run this as postgres superuser to create shared access
-- UPDATED for flowspace_dev database

-- Create a user for collaborators (skip if already exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'flowspace_user') THEN
    CREATE USER flowspace_user WITH PASSWORD 'FlowSpace2024!';
    RAISE NOTICE '✅ Created flowspace_user';
  ELSE
    RAISE NOTICE '⚠️ flowspace_user already exists';
  END IF;
END $$;

-- Grant privileges to the user
GRANT ALL PRIVILEGES ON DATABASE flow_space TO flowspace_user;

-- Connect to the flow_space database
\c flow_space;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO flowspace_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO flowspace_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO flowspace_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO flowspace_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO flowspace_user;

-- Show the user was created successfully
\du flowspace_user;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '🎉 Shared database setup complete!';
  RAISE NOTICE '📋 Database: flow_space';
  RAISE NOTICE '🌐 Host: 172.19.48.1';
  RAISE NOTICE '👤 User: flowspace_user';
  RAISE NOTICE '🔒 Password: FlowSpace2024!';
END $$;
