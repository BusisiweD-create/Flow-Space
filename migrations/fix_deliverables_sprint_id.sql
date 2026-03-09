-- Fix deliverables table to add missing sprint_id column
-- This migration addresses the "deliverables.sprint_id column not found" warnings

-- Add sprint_id column to deliverables table if it doesn't exist
DO $$
BEGIN;

-- Check if sprint_id column exists and add it if not
IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'deliverables' 
    AND column_name = 'sprint_id'
    AND table_schema = 'public'
) THEN
    ALTER TABLE deliverables ADD COLUMN sprint_id UUID;
    
    -- Add foreign key constraint if sprints table exists
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'sprints' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE deliverables 
        ADD CONSTRAINT fk_deliverables_sprint 
        FOREIGN KEY (sprint_id) REFERENCES sprints(sprint_id) 
        ON DELETE SET NULL;
    END IF;
    
    -- Create index for better performance
    CREATE INDEX IF NOT EXISTS idx_deliverables_sprint_id 
    ON deliverables(sprint_id);
    
    RAISE NOTICE 'Added sprint_id column to deliverables table';
END IF;

COMMIT;
$$;
