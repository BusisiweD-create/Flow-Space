-- Add missing columns to existing tables
-- Run this to add any missing columns needed for the backend

-- Add missing columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS company TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verification_code TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS reset_token TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS reset_token_expiry TIMESTAMP WITH TIME ZONE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Grant permissions to flowspace_user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO flowspace_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO flowspace_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO flowspace_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO flowspace_user;
