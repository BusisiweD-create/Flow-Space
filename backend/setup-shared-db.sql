-- Setup script for shared PostgreSQL database
-- Run this as postgres superuser to create shared access

-- Create a user for collaborators
CREATE USER flowspace_user WITH PASSWORD 'FlowSpace2024!';

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
