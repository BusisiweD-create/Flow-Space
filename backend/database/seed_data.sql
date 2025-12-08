-- Flow-Space Database Seed Data
-- Insert initial roles, permissions, and sample data

-- Insert user roles
INSERT INTO user_roles (name, display_name, description, color, icon) VALUES
('teamMember', 'Team Member', 'Can create deliverables and view own work', '#2196F3', 'person'),
('deliveryLead', 'Delivery Lead', 'Can manage team and submit for client review', '#FF9800', 'leaderboard'),
('clientReviewer', 'Client Reviewer', 'Can review and approve deliverables', '#4CAF50', 'verified_user'),
('systemAdmin', 'System Admin', 'Full system access and administration', '#9C27B0', 'admin_panel_settings');

-- Insert permissions
INSERT INTO permissions (name, description) VALUES
('create_deliverable', 'Create new deliverables'),
('edit_deliverable', 'Edit existing deliverables'),
('delete_deliverable', 'Delete deliverables'),
('submit_for_review', 'Submit deliverables for client review'),
('approve_deliverable', 'Approve or reject deliverables'),
('view_team_dashboard', 'View team performance dashboard'),
('view_client_review', 'Access client review interface'),
('manage_users', 'Manage user accounts and roles'),
('view_audit_logs', 'View system audit logs'),
('override_readiness_gate', 'Override release readiness gates'),
('view_all_deliverables', 'View all team deliverables'),
('manage_projects', 'Create and manage projects'),
('manage_sprints', 'Create and manage sprints'),
('view_reports', 'View and generate reports'),
('manage_notifications', 'Manage system notifications');

-- Insert role permissions
-- Team Member permissions
INSERT INTO role_permissions (role_id, permission_id) 
SELECT ur.id, p.id 
FROM user_roles ur, permissions p 
WHERE ur.name = 'teamMember' 
AND p.name IN ('create_deliverable', 'edit_deliverable', 'view_reports');

-- Delivery Lead permissions
INSERT INTO role_permissions (role_id, permission_id) 
SELECT ur.id, p.id 
FROM user_roles ur, permissions p 
WHERE ur.name = 'deliveryLead' 
AND p.name IN (
    'create_deliverable', 'edit_deliverable', 'delete_deliverable',
    'submit_for_review', 'view_team_dashboard', 'view_all_deliverables',
    'override_readiness_gate', 'manage_projects', 'manage_sprints',
    'view_reports', 'manage_notifications'
);

-- Client Reviewer permissions
INSERT INTO role_permissions (role_id, permission_id) 
SELECT ur.id, p.id 
FROM user_roles ur, permissions p 
WHERE ur.name = 'clientReviewer' 
AND p.name IN (
    'approve_deliverable', 'view_client_review', 'view_reports'
);

-- System Admin permissions (all permissions)
INSERT INTO role_permissions (role_id, permission_id) 
SELECT ur.id, p.id 
FROM user_roles ur, permissions p 
WHERE ur.name = 'systemAdmin';

-- Insert sample project
INSERT INTO projects (id, name, description, owner_id, status) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Flow-Space Development', 'Main development project for Flow-Space application', 
 (SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1), 'active');

-- Insert sample sprint
INSERT INTO sprints (id, name, project_id, start_date, end_date, committed_points, completed_points, velocity, test_pass_rate, defect_count, status) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Sprint 1 - Authentication', 
 '550e8400-e29b-41d4-a716-446655440000',
 CURRENT_TIMESTAMP - INTERVAL '14 days',
 CURRENT_TIMESTAMP - INTERVAL '7 days',
 21, 18, 18.0, 95.5, 3, 'completed'),
('550e8400-e29b-41d4-a716-446655440002', 'Sprint 2 - Role Management', 
 '550e8400-e29b-41d4-a716-446655440000',
 CURRENT_TIMESTAMP - INTERVAL '7 days',
 CURRENT_TIMESTAMP,
 19, 19, 19.0, 98.2, 1, 'completed'),
('550e8400-e29b-41d4-a716-446655440003', 'Sprint 3 - Dashboard Features', 
 '550e8400-e29b-41d4-a716-446655440000',
 CURRENT_TIMESTAMP,
 CURRENT_TIMESTAMP + INTERVAL '7 days',
 25, 12, 0.0, 92.1, 2, 'in_progress');

-- Insert sample deliverables
INSERT INTO deliverables (id, title, description, status, project_id, created_by, due_date, definition_of_done, evidence, readiness_gates) VALUES
('550e8400-e29b-41d4-a716-446655440010', 'User Authentication System', 
 'Complete user login, registration, and role-based access control',
 'submitted',
 '550e8400-e29b-41d4-a716-446655440000',
 (SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1),
 CURRENT_TIMESTAMP + INTERVAL '2 days',
 '["All unit tests pass", "Code review completed", "Security audit passed", "Documentation updated"]',
 '["test_results.pdf", "code_review.pdf", "security_audit.pdf"]',
 '["Code Quality Gate", "Security Gate", "Performance Gate"]'),
('550e8400-e29b-41d4-a716-446655440011', 'Payment Integration', 
 'Stripe payment gateway integration with subscription management',
 'draft',
 '550e8400-e29b-41d4-a716-446655440000',
 (SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1),
 CURRENT_TIMESTAMP + INTERVAL '7 days',
 '["Payment flow tested", "PCI compliance verified", "Error handling implemented", "User documentation created"]',
 '[]',
 '["Security Gate", "Compliance Gate"]'),
('550e8400-e29b-41d4-a716-446655440012', 'Mobile App Release', 
 'iOS and Android app store deployment',
 'approved',
 '550e8400-e29b-41d4-a716-446655440000',
 (SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1),
 CURRENT_TIMESTAMP - INTERVAL '1 day',
 '["App store approval received", "Performance testing completed", "User acceptance testing passed", "Release notes published"]',
 '["app_store_approval.pdf", "performance_test.pdf", "uat_report.pdf"]',
 '["Quality Gate", "Performance Gate"]');

-- Link deliverables to sprints
INSERT INTO sprint_deliverables (sprint_id, deliverable_id, points) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440010', 8),
('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440011', 13),
('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440012', 5);

-- Insert sample notifications
INSERT INTO notifications (user_id, title, message, type, action_url) VALUES
((SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1), 
 'Welcome to Flow-Space!', 
 'Your account has been created successfully. You can now start managing your projects and deliverables.',
 'success', '/dashboard'),
((SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1), 
 'New Deliverable Submitted', 
 'User Authentication System has been submitted for review.',
 'info', '/approvals'),
((SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1), 
 'Sprint Update', 
 'Sprint 2 - Role Management has been completed with 100% velocity.',
 'success', '/sprint-console');

-- Insert sample audit logs
INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, ip_address, user_agent) VALUES
((SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1), 
 'user_registered', 'user', (SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1),
 '{"email": "admin@flowspace.com", "role": "systemAdmin"}', 
 '127.0.0.1', 'Mozilla/5.0 (Windows) AppleWebKit/537.36'),
((SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1), 
 'deliverable_created', 'deliverable', '550e8400-e29b-41d4-a716-446655440010',
 '{"title": "User Authentication System", "status": "draft"}', 
 '127.0.0.1', 'Mozilla/5.0 (Windows) AppleWebKit/537.36'),
((SELECT id FROM users WHERE email = 'admin@flowspace.com' LIMIT 1), 
 'deliverable_submitted', 'deliverable', '550e8400-e29b-41d4-a716-446655440010',
 '{"title": "User Authentication System", "status": "submitted"}', 
 '127.0.0.1', 'Mozilla/5.0 (Windows) AppleWebKit/537.36');
