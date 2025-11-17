-- Fix deliverables table to match backend expectations
-- This migration ensures all required columns exist

-- Step 1: Check and add missing columns
DO $$ 
BEGIN
    -- Add due_date column if missing
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'due_date'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN due_date TIMESTAMP;
        RAISE NOTICE '✅ Added due_date column to deliverables table';
    END IF;
    
    -- Add definition_of_done column if missing (as TEXT, not JSONB)
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'definition_of_done'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN definition_of_done TEXT;
        RAISE NOTICE '✅ Added definition_of_done column to deliverables table';
    END IF;
    
    -- Ensure priority column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'priority'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN priority VARCHAR(50) DEFAULT 'Medium';
        RAISE NOTICE '✅ Added priority column to deliverables table';
    END IF;
    
    -- Ensure status column exists with proper default
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'status'
    ) THEN
        -- Update default if needed
        ALTER TABLE deliverables ALTER COLUMN status SET DEFAULT 'Draft';
        RAISE NOTICE '✅ Updated status default to Draft';
    ELSE
        ALTER TABLE deliverables ADD COLUMN status VARCHAR(50) DEFAULT 'Draft';
        RAISE NOTICE '✅ Added status column to deliverables table';
    END IF;
    
    -- Ensure created_by column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN created_by UUID REFERENCES users(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Added created_by column to deliverables table';
    END IF;
    
    -- Ensure assigned_to column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'assigned_to'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN assigned_to UUID REFERENCES users(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Added assigned_to column to deliverables table';
    END IF;
    
    -- Ensure sprint_id column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'sprint_id'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN sprint_id UUID;
        RAISE NOTICE '✅ Added sprint_id column to deliverables table';
    END IF;
    
    -- Ensure title column exists and is NOT NULL
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'title'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN title VARCHAR(255) NOT NULL;
        RAISE NOTICE '✅ Added title column to deliverables table';
    END IF;
    
    -- Ensure description column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'description'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN description TEXT;
        RAISE NOTICE '✅ Added description column to deliverables table';
    END IF;
    
    -- Ensure created_at and updated_at columns exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN created_at TIMESTAMP DEFAULT NOW();
        RAISE NOTICE '✅ Added created_at column to deliverables table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'deliverables' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE deliverables ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
        RAISE NOTICE '✅ Added updated_at column to deliverables table';
    END IF;
    
END $$;

-- Step 2: Show final table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'deliverables'
ORDER BY ordinal_position;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🎉 Deliverables table migration completed successfully!';
    RAISE NOTICE '📋 The table now has all required columns for deliverable creation';
END $$;

