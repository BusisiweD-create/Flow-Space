-- Fix projects table to add owner_id column
-- This migration is safe to run multiple times

-- Step 1: Add owner_id column if it doesn't exist
DO $$ 
BEGIN
    -- Check if owner_id column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'projects' 
        AND column_name = 'owner_id'
    ) THEN
        -- Add owner_id column
        ALTER TABLE projects ADD COLUMN owner_id UUID;
        RAISE NOTICE '✅ Added owner_id column to projects table';
        
        -- If there's a created_by column, copy data from it
        IF EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'projects' 
            AND column_name = 'created_by'
        ) THEN
            UPDATE projects SET owner_id = created_by WHERE owner_id IS NULL;
            RAISE NOTICE '✅ Copied data from created_by to owner_id';
        END IF;
        
        -- Add foreign key constraint
        ALTER TABLE projects 
        ADD CONSTRAINT fk_projects_owner 
        FOREIGN KEY (owner_id) 
        REFERENCES users(id) 
        ON DELETE CASCADE;
        
        RAISE NOTICE '✅ Added foreign key constraint';
    ELSE
        RAISE NOTICE '✅ owner_id column already exists';
    END IF;
END $$;

-- Step 2: Ensure other necessary columns exist
DO $$
BEGIN
    -- Add key column if missing (optional, for project key like 'PROJ-123')
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'projects' AND column_name = 'key'
    ) THEN
        ALTER TABLE projects ADD COLUMN key VARCHAR(50);
        RAISE NOTICE '✅ Added key column';
    END IF;
    
    -- Add project_type column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'projects' AND column_name = 'project_type'
    ) THEN
        ALTER TABLE projects ADD COLUMN project_type VARCHAR(50) DEFAULT 'agile';
        RAISE NOTICE '✅ Added project_type column';
    END IF;
    
    -- Add start_date column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'projects' AND column_name = 'start_date'
    ) THEN
        ALTER TABLE projects ADD COLUMN start_date TIMESTAMP;
        RAISE NOTICE '✅ Added start_date column';
    END IF;
    
    -- Add end_date column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'projects' AND column_name = 'end_date'
    ) THEN
        ALTER TABLE projects ADD COLUMN end_date TIMESTAMP;
        RAISE NOTICE '✅ Added end_date column';
    END IF;
END $$;

-- Step 3: Show final table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'projects'
ORDER BY ordinal_position;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🎉 Projects table migration completed successfully!';
END $$;

