-- Reduce CORS logging verbosity in production
-- Update environment variables to reduce log noise

-- This will be handled in the backend code
-- Adding this migration for documentation purposes

DO $$
BEGIN;

-- Add a configuration table for logging settings
CREATE TABLE IF NOT EXISTS app_config (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert CORS logging configuration
INSERT INTO app_config (key, value, description) VALUES 
('cors_logging_enabled', 'false', 'Enable/disable CORS logging in production'),
('log_level', 'warn', 'Set logging level (error, warn, info, debug)')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = CURRENT_TIMESTAMP;

RAISE NOTICE 'Added app configuration for logging settings';

COMMIT;
$$;
