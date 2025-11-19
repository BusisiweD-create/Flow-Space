-- Check projects table structure and data
-- Run this in pgAdmin or psql to diagnose issues

-- 1. Check if table exists and see its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'projects'
ORDER BY ordinal_position;

-- 2. Check existing projects
SELECT 
    id, 
    name, 
    owner_id, 
    status, 
    created_at
FROM projects
LIMIT 10;

-- 3. Check if owner_id values exist in users table
SELECT 
    p.id as project_id,
    p.name as project_name,
    p.owner_id,
    u.id as user_id,
    u.name as user_name
FROM projects p
LEFT JOIN users u ON p.owner_id = u.id;

-- 4. List all users (to verify IDs)
SELECT id, name, email, role FROM users;

-- 5. Try a test insert (will show exact error if any)
-- DO $$
-- BEGIN
--     INSERT INTO projects (name, description, status, owner_id)
--     VALUES ('Test Project', 'Test Description', 'active', 
--             (SELECT id FROM users LIMIT 1));
--     
--     RAISE NOTICE 'Test insert successful';
--     ROLLBACK; -- Don't actually save it
-- END $$;

