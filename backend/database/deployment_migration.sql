-- Flow-Space Database Migration for Deployment
-- This script ensures all necessary tables exist and have the correct structure
-- Run this before deploying to production

-- ==========================================
-- 1. Ensure Core Tables Exist
-- ==========================================

-- Users table (should exist from schema)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE '✅ Users table exists';
    ELSE
        RAISE NOTICE '❌ Users table missing - creating...';
    END IF;
END $$;

-- Projects table with all required fields
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'projects') THEN
        RAISE NOTICE '✅ Projects table exists - checking columns...';
        
        -- Add missing columns if they don't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'projects' AND column_name = 'owner_id'
        ) THEN
            ALTER TABLE projects ADD COLUMN owner_id UUID;
            RAISE NOTICE '✅ Added owner_id column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'projects' AND column_name = 'key'
        ) THEN
            ALTER TABLE projects ADD COLUMN key VARCHAR(50);
            RAISE NOTICE '✅ Added key column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'projects' AND column_name = 'client_name'
        ) THEN
            ALTER TABLE projects ADD COLUMN client_name VARCHAR(255);
            RAISE NOTICE '✅ Added client_name column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'projects' AND column_name = 'start_date'
        ) THEN
            ALTER TABLE projects ADD COLUMN start_date TIMESTAMP;
            RAISE NOTICE '✅ Added start_date column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'projects' AND column_name = 'end_date'
        ) THEN
            ALTER TABLE projects ADD COLUMN end_date TIMESTAMP;
            RAISE NOTICE '✅ Added end_date column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'projects' AND column_name = 'priority'
        ) THEN
            ALTER TABLE projects ADD COLUMN priority VARCHAR(50) DEFAULT 'medium';
            RAISE NOTICE '✅ Added priority column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'projects' AND column_name = 'project_type'
        ) THEN
            ALTER TABLE projects ADD COLUMN project_type VARCHAR(100) DEFAULT 'agile';
            RAISE NOTICE '✅ Added project_type column';
        END IF;
        
        -- Add foreign key constraint for owner_id if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE table_name = 'projects' AND constraint_name = 'fk_projects_owner'
        ) THEN
            ALTER TABLE projects 
            ADD CONSTRAINT fk_projects_owner 
            FOREIGN KEY (owner_id) 
            REFERENCES users(id) 
            ON DELETE CASCADE;
            RAISE NOTICE '✅ Added foreign key constraint for owner_id';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Projects table missing - please run schema.sql first';
    END IF;
END $$;

-- Project members table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'project_members') THEN
        RAISE NOTICE '✅ Project members table exists';
    ELSE
        RAISE NOTICE '❌ Project members table missing - please run schema.sql first';
    END IF;
END $$;

-- Sprints table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sprints') THEN
        RAISE NOTICE '✅ Sprints table exists';
    ELSE
        RAISE NOTICE '❌ Sprints table missing - please run schema.sql first';
    END IF;
END $$;

-- ==========================================
-- 2. Add Sample Project for Testing
-- ==========================================

-- Insert sample ACPS project if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM projects WHERE name = 'ACPS Project'
    ) THEN
        RAISE NOTICE '✅ ACPS Project already exists';
    ELSE
        INSERT INTO projects (
            id, name, key, description, client_name, owner_id, 
            status, start_date, end_date, priority, project_type,
            created_at, updated_at
        ) VALUES (
            'c93009f3-0e7a-4272-9327-afcfa68ba503',
            'ACPS Project',
            'ACPS',
            'Advanced Customer Portal System - A comprehensive customer management platform with real-time analytics and reporting capabilities.',
            'ACPS Corporation',
            '2bf58eec-6bca-4056-b656-0b66c34eeb94', -- Busisiwe Dhlamini's user ID
            'active',
            '2024-01-15',
            '2024-06-30',
            'high',
            'web',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        RAISE NOTICE '✅ Created ACPS Project sample';
    END IF;
END $$;

-- Insert sample Corner Bus project if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM projects WHERE name = 'Corner Bus Project'
    ) THEN
        RAISE NOTICE '✅ Corner Bus Project already exists';
    ELSE
        INSERT INTO projects (
            id, name, key, description, client_name, owner_id,
            status, start_date, end_date, priority, project_type,
            created_at, updated_at
        ) VALUES (
            'corner-bus-002',
            'Corner Bus Project',
            'CBUS',
            'Public transportation management system for corner bus routes with real-time tracking and passenger analytics.',
            'City Transit Authority',
            '2bf58eec-6bca-4056-b656-0b66c34eeb94', -- Busisiwe Dhlamini's user ID
            'active',
            '2024-02-01',
            '2024-08-31',
            'medium',
            'mobile',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        RAISE NOTICE '✅ Created Corner Bus Project sample';
    END IF;
END $$;

-- ==========================================
-- 3. Add Sample Project Members
-- ==========================================

-- Add members for ACPS Project
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM project_members pm 
        JOIN projects p ON pm.project_id = p.id 
        WHERE p.name = 'ACPS Project' LIMIT 1
    ) THEN
        RAISE NOTICE '✅ ACPS Project members already exist';
    ELSE
        INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES
        ('c93009f3-0e7a-4272-9327-afcfa68ba503', 'user-001', 'owner', '2024-01-10'),
        ('c93009f3-0e7a-4272-9327-afcfa68ba503', 'user-002', 'contributor', '2024-01-12'),
        ('c93009f3-0e7a-4272-9327-afcfa68ba503', 'user-003', 'viewer', '2024-01-15');
        RAISE NOTICE '✅ Added members to ACPS Project';
    END IF;
END $$;

-- Add members for Corner Bus Project
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM project_members pm 
        JOIN projects p ON pm.project_id = p.id 
        WHERE p.name = 'Corner Bus Project' LIMIT 1
    ) THEN
        RAISE NOTICE '✅ Corner Bus Project members already exist';
    ELSE
        INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES
        ('corner-bus-002', 'user-004', 'owner', '2024-01-25'),
        ('corner-bus-002', 'user-005', 'contributor', '2024-02-01'),
        ('corner-bus-002', 'user-006', 'contributor', '2024-02-03');
        RAISE NOTICE '✅ Added members to Corner Bus Project';
    END IF;
END $$;

-- ==========================================
-- 4. Create Sample Users (if they don't exist)
-- ==========================================

DO $$
BEGIN
    -- Create sample users for project members
    IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'john.smith@company.com') THEN
        RAISE NOTICE '✅ Sample users already exist';
    ELSE
        INSERT INTO users (id, email, name, role, is_active, created_at, updated_at) VALUES
        ('user-001', 'john.smith@company.com', 'John Smith', 'teamMember', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('user-002', 'sarah.j@company.com', 'Sarah Johnson', 'teamMember', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('user-003', 'mike.w@company.com', 'Mike Wilson', 'teamMember', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('user-004', 'emily.d@company.com', 'Emily Davis', 'teamMember', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('user-005', 'robert.c@company.com', 'Robert Chen', 'teamMember', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('user-006', 'lisa.a@company.com', 'Lisa Anderson', 'teamMember', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        RAISE NOTICE '✅ Created sample users';
    END IF;
END $$;

-- ==========================================
-- 5. Final Verification
-- ==========================================

-- Show current projects
DO $$
BEGIN
    RAISE NOTICE '🔍 Current projects in database:';
    FOR project IN 
        SELECT id, name, key, status FROM projects 
        ORDER BY created_at
    LOOP
        RAISE NOTICE '   - % (%) (%) - %', project.name, project.key, project.id, project.status;
    END LOOP;
    
    RAISE NOTICE '🎉 Database migration completed successfully!';
END $$;
