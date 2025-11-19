-- Create tables for sign-off reports system
-- Run this in the flow_space database
-- Run this if you don't have these tables yet

-- Make sure you're connected to the correct database
-- \c flow_space

-- 1. Sign-off reports table
CREATE TABLE IF NOT EXISTS sign_off_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id UUID NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'draft',
    content JSONB DEFAULT '{}',
    evidence JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Client reviews table
CREATE TABLE IF NOT EXISTS client_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    feedback TEXT,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 3. Deliverables table (if missing)
CREATE TABLE IF NOT EXISTS deliverables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    definition_of_done TEXT,
    status VARCHAR(50) DEFAULT 'not_started',
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    project_id UUID,
    sprint_id UUID,
    priority VARCHAR(50) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_sign_off_reports_deliverable ON sign_off_reports(deliverable_id);
CREATE INDEX IF NOT EXISTS idx_sign_off_reports_status ON sign_off_reports(status);
CREATE INDEX IF NOT EXISTS idx_sign_off_reports_created_by ON sign_off_reports(created_by);
CREATE INDEX IF NOT EXISTS idx_client_reviews_report ON client_reviews(report_id);
CREATE INDEX IF NOT EXISTS idx_deliverables_status ON deliverables(status);
CREATE INDEX IF NOT EXISTS idx_deliverables_assigned_to ON deliverables(assigned_to);

-- 5. Add some sample deliverables for testing
INSERT INTO deliverables (id, title, description, status, assigned_to, project_id)
SELECT 
    gen_random_uuid(),
    'Sample Deliverable ' || i,
    'This is a test deliverable for report creation',
    'in_progress',
    (SELECT id FROM users LIMIT 1),
    (SELECT id FROM projects LIMIT 1)
FROM generate_series(1, 3) AS i
ON CONFLICT DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Sign-off reports tables created successfully!';
    RAISE NOTICE '📝 Tables: sign_off_reports, client_reviews, deliverables';
    RAISE NOTICE '🎯 Sample deliverables added for testing';
END $$;

