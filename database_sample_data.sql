-- =====================================================
-- SAMPLE DATA FOR DELIVERABLE & SPRINT SIGN-OFF HUB
-- =====================================================
-- This file contains sample data for testing and development
-- =====================================================

-- =====================================================
-- 1. SAMPLE USERS
-- =====================================================

INSERT INTO users (id, email, password_hash, first_name, last_name, company, role) VALUES
('00000000-0000-0000-0000-000000000001', 'john.doe@techcorp.com', '$2b$12$hash1', 'John', 'Doe', 'TechCorp', 'project_manager'),
('00000000-0000-0000-0000-000000000002', 'jane.smith@techcorp.com', '$2b$12$hash2', 'Jane', 'Smith', 'TechCorp', 'developer'),
('00000000-0000-0000-0000-000000000003', 'mike.johnson@techcorp.com', '$2b$12$hash3', 'Mike', 'Johnson', 'TechCorp', 'developer'),
('00000000-0000-0000-0000-000000000004', 'sarah.wilson@techcorp.com', '$2b$12$hash4', 'Sarah', 'Wilson', 'TechCorp', 'developer'),
('00000000-0000-0000-0000-000000000005', 'client@clientcorp.com', '$2b$12$hash5', 'Client', 'User', 'ClientCorp', 'client'),
('00000000-0000-0000-0000-000000000006', 'stakeholder@clientcorp.com', '$2b$12$hash6', 'Stakeholder', 'User', 'ClientCorp', 'stakeholder');

-- =====================================================
-- 2. SAMPLE PROJECTS
-- =====================================================

INSERT INTO projects (id, name, description, status, start_date, end_date, created_by) VALUES
('00000000-0000-0000-0000-000000000100', 'Authentication System', 'User authentication and authorization system with MFA', 'active', '2024-01-01', '2024-03-31', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000101', 'Payment Integration', 'Stripe payment gateway integration', 'active', '2024-02-01', '2024-04-30', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000102', 'Dashboard Analytics', 'Analytics dashboard with reporting', 'active', '2024-03-01', '2024-05-31', '00000000-0000-0000-0000-000000000001');

-- =====================================================
-- 3. PROJECT MEMBERS
-- =====================================================

INSERT INTO project_members (project_id, user_id, role) VALUES
-- Authentication System project
('00000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000001', 'owner'),
('00000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000002', 'member'),
('00000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000003', 'member'),
('00000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000005', 'viewer'),
-- Payment Integration project
('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'owner'),
('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000004', 'member'),
('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000005', 'viewer'),
-- Dashboard Analytics project
('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000001', 'owner'),
('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000002', 'member'),
('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000006', 'viewer');

-- =====================================================
-- 4. SAMPLE SPRINTS
-- =====================================================

INSERT INTO sprints (id, project_id, name, description, start_date, end_date, status, created_by) VALUES
-- Authentication System sprints
('00000000-0000-0000-0000-000000000200', '00000000-0000-0000-0000-000000000100', 'Sprint 1 - Foundation', 'Basic authentication setup', '2024-01-01', '2024-01-14', 'completed', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000100', 'Sprint 2 - Core Features', 'Login, registration, password reset', '2024-01-15', '2024-01-28', 'completed', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000100', 'Sprint 3 - MFA Integration', 'Multi-factor authentication', '2024-01-29', '2024-02-11', 'active', '00000000-0000-0000-0000-000000000001'),
-- Payment Integration sprints
('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000101', 'Sprint 1 - Payment Setup', 'Stripe integration setup', '2024-02-01', '2024-02-14', 'completed', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000101', 'Sprint 2 - Payment Processing', 'Payment flow implementation', '2024-02-15', '2024-02-28', 'active', '00000000-0000-0000-0000-000000000001');

-- =====================================================
-- 5. SAMPLE SPRINT METRICS
-- =====================================================

INSERT INTO sprint_metrics (id, sprint_id, committed_points, completed_points, carried_over_points, test_pass_rate, defects_opened, defects_closed, critical_defects, high_defects, medium_defects, low_defects, code_review_completion, documentation_status, risks, mitigations, scope_changes, uat_notes, recorded_by) VALUES
-- Sprint 1 metrics
('00000000-0000-0000-0000-000000000300', '00000000-0000-0000-0000-000000000200', 20, 18, 2, 95.5, 3, 3, 0, 1, 1, 1, 100.0, 85.0, 'Initial authentication complexity', 'Extended testing phase, additional security review', 'Added MFA requirement mid-sprint', 'Client feedback incorporated successfully', '00000000-0000-0000-0000-000000000002'),
-- Sprint 2 metrics
('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000201', 22, 20, 2, 97.2, 2, 2, 0, 0, 1, 1, 100.0, 95.0, 'Integration complexity with existing systems', 'Dedicated integration testing, API documentation', 'Minor UI adjustments based on feedback', 'Excellent user feedback, ready for production', '00000000-0000-0000-0000-000000000002'),
-- Sprint 3 metrics
('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000202', 18, 16, 2, 98.1, 1, 1, 0, 0, 0, 1, 100.0, 100.0, 'None identified', 'N/A', 'None', 'Final testing completed, all acceptance criteria met', '00000000-0000-0000-0000-000000000002');

-- =====================================================
-- 6. SAMPLE DELIVERABLES
-- =====================================================

INSERT INTO deliverables (id, project_id, title, description, status, due_date, created_by, assigned_to, submitted_by, submitted_at) VALUES
('00000000-0000-0000-0000-000000000400', '00000000-0000-0000-0000-000000000100', 'User Authentication System', 'Complete user login, registration, and role-based access control with multi-factor authentication', 'submitted', '2024-02-15', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '2024-02-10 10:30:00'),
('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000101', 'Payment Integration', 'Stripe payment gateway integration with subscription management', 'draft', '2024-03-15', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', NULL, NULL),
('00000000-0000-0000-0000-000000000402', '00000000-0000-0000-0000-000000000102', 'Dashboard Analytics', 'Analytics dashboard with comprehensive reporting features', 'change_requested', '2024-04-15', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '2024-02-05 14:20:00');

-- =====================================================
-- 7. DELIVERABLE DOD ITEMS
-- =====================================================

INSERT INTO deliverable_dod_items (id, deliverable_id, item_text, is_completed, completed_at, completed_by) VALUES
-- Authentication System DoD items
('00000000-0000-0000-0000-000000000500', '00000000-0000-0000-0000-000000000400', 'All unit tests pass with >90% coverage', true, '2024-02-08 09:00:00', '00000000-0000-0000-0000-000000000002'),
('00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000400', 'Code review completed by senior developer', true, '2024-02-08 10:00:00', '00000000-0000-0000-0000-000000000003'),
('00000000-0000-0000-0000-000000000502', '00000000-0000-0000-0000-000000000400', 'Security audit passed with no critical issues', true, '2024-02-09 11:00:00', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000503', '00000000-0000-0000-0000-000000000400', 'Documentation updated and reviewed', true, '2024-02-09 12:00:00', '00000000-0000-0000-0000-000000000002'),
('00000000-0000-0000-0000-000000000504', '00000000-0000-0000-0000-000000000400', 'Performance benchmarks met', true, '2024-02-09 13:00:00', '00000000-0000-0000-0000-000000000002'),
('00000000-0000-0000-0000-000000000505', '00000000-0000-0000-0000-000000000400', 'User acceptance testing completed', true, '2024-02-10 14:00:00', '00000000-0000-0000-0000-000000000005');

-- =====================================================
-- 8. DELIVERABLE EVIDENCE
-- =====================================================

INSERT INTO deliverable_evidence (id, deliverable_id, link_url, link_type, description) VALUES
-- Authentication System evidence
('00000000-0000-0000-0000-000000000600', '00000000-0000-0000-0000-000000000400', 'https://demo.techcorp.com/auth', 'demo', 'Live demo environment'),
('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000400', 'https://github.com/techcorp/auth-system', 'repository', 'Source code repository'),
('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000400', 'https://docs.techcorp.com/auth-guide', 'documentation', 'User documentation'),
('00000000-0000-0000-0000-000000000603', '00000000-0000-0000-0000-000000000400', 'https://test-results.techcorp.com/auth-coverage', 'test_results', 'Test coverage report');

-- =====================================================
-- 9. DELIVERABLE-SPRINT RELATIONSHIPS
-- =====================================================

INSERT INTO deliverable_sprints (deliverable_id, sprint_id) VALUES
('00000000-0000-0000-0000-000000000400', '00000000-0000-0000-0000-000000000200'),
('00000000-0000-0000-0000-000000000400', '00000000-0000-0000-0000-000000000201'),
('00000000-0000-0000-0000-000000000400', '00000000-0000-0000-0000-000000000202'),
('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000203'),
('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000204');

-- =====================================================
-- 10. SAMPLE SIGN-OFF REPORTS
-- =====================================================

INSERT INTO sign_off_reports (id, deliverable_id, report_title, report_content, status, created_by, submitted_by, submitted_at) VALUES
('00000000-0000-0000-0000-000000000700', '00000000-0000-0000-0000-000000000400', 'Sign-Off Report: User Authentication System', '## Executive Summary

This report provides a comprehensive overview of the User Authentication System deliverable, including sprint performance metrics, quality indicators, and readiness for client approval.

## Deliverable Overview

**Title:** User Authentication System
**Description:** Complete user login, registration, and role-based access control with multi-factor authentication
**Due Date:** 15/02/2024
**Status:** Submitted

## Definition of Done Checklist

1. ✅ All unit tests pass with >90% coverage
2. ✅ Code review completed by senior developer
3. ✅ Security audit passed with no critical issues
4. ✅ Documentation updated and reviewed
5. ✅ Performance benchmarks met
6. ✅ User acceptance testing completed

## Evidence & Artifacts

1. [Demo Environment](https://demo.techcorp.com/auth)
2. [Source Code Repository](https://github.com/techcorp/auth-system)
3. [User Documentation](https://docs.techcorp.com/auth-guide)
4. [Test Coverage Report](https://test-results.techcorp.com/auth-coverage)

## Sprint Performance Summary

**Total Committed Points:** 60
**Total Completed Points:** 56
**Completion Rate:** 93.3%
**Average Test Pass Rate:** 96.9%
**Total Defects:** 6
**Resolved Defects:** 6
**Defect Resolution Rate:** 100.0%

## Quality Indicators

All sprints maintained high quality standards with:
- Test pass rates consistently above 95%
- Complete code review coverage
- Comprehensive documentation
- Zero critical defects in production

## Risk Assessment

No significant risks identified during development.

## Known Limitations

- MFA setup requires admin configuration
- Password reset emails may take up to 5 minutes to deliver
- Session timeout is set to 8 hours for security

## Next Steps

- Deploy to production environment
- Monitor authentication metrics
- Schedule user training sessions
- Plan future enhancements based on user feedback', 'submitted', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '2024-02-10 15:00:00');

-- =====================================================
-- 11. REPORT-SPRINT RELATIONSHIPS
-- =====================================================

INSERT INTO report_sprints (report_id, sprint_id) VALUES
('00000000-0000-0000-0000-000000000700', '00000000-0000-0000-0000-000000000200'),
('00000000-0000-0000-0000-000000000700', '00000000-0000-0000-0000-000000000201'),
('00000000-0000-0000-0000-000000000700', '00000000-0000-0000-0000-000000000202');

-- =====================================================
-- 12. SAMPLE NOTIFICATIONS
-- =====================================================

INSERT INTO notifications (id, user_id, title, message, type, priority, is_read, deliverable_id, report_id, created_at) VALUES
('00000000-0000-0000-0000-000000000800', '00000000-0000-0000-0000-000000000005', 'Deliverable Review Required', 'User Authentication System is ready for your review and approval.', 'review', 'high', false, '00000000-0000-0000-0000-000000000400', '00000000-0000-0000-0000-000000000700', '2024-02-10 16:00:00'),
('00000000-0000-0000-0000-000000000801', '00000000-0000-0000-0000-000000000001', 'Sprint Metrics Updated', 'Sprint 3 metrics have been updated with latest performance data.', 'metrics', 'medium', true, NULL, NULL, '2024-02-09 10:00:00'),
('00000000-0000-0000-0000-000000000802', '00000000-0000-0000-0000-000000000001', 'Change Request Submitted', 'Dashboard Analytics deliverable has a new change request from client.', 'change_request', 'high', false, '00000000-0000-0000-0000-000000000402', NULL, '2024-02-05 16:30:00'),
('00000000-0000-0000-0000-000000000803', '00000000-0000-0000-0000-000000000001', 'Report Generated', 'Sign-off report for User Authentication System has been generated and is ready for review.', 'report', 'medium', true, '00000000-0000-0000-0000-000000000400', '00000000-0000-0000-0000-000000000700', '2024-02-10 15:30:00'),
('00000000-0000-0000-0000-000000000804', '00000000-0000-0000-0000-000000000001', 'Reminder: Review Due Soon', 'User Authentication System deliverable review is due in 24 hours.', 'reminder', 'urgent', false, '00000000-0000-0000-0000-000000000400', NULL, '2024-02-11 10:00:00');

-- =====================================================
-- 13. SAMPLE ACTIVITY LOGS
-- =====================================================

INSERT INTO activity_logs (id, user_id, entity_type, entity_id, action, description, created_at) VALUES
('00000000-0000-0000-0000-000000000900', '00000000-0000-0000-0000-000000000001', 'deliverable', '00000000-0000-0000-0000-000000000400', 'created', 'Created deliverable: User Authentication System', '2024-01-15 09:00:00'),
('00000000-0000-0000-0000-000000000901', '00000000-0000-0000-0000-000000000001', 'deliverable', '00000000-0000-0000-0000-000000000400', 'submitted', 'Submitted deliverable for review', '2024-02-10 10:30:00'),
('00000000-0000-0000-0000-000000000902', '00000000-0000-0000-0000-000000000001', 'report', '00000000-0000-0000-0000-000000000700', 'created', 'Generated sign-off report', '2024-02-10 15:00:00'),
('00000000-0000-0000-0000-000000000903', '00000000-0000-0000-0000-000000000002', 'sprint_metrics', '00000000-0000-0000-0000-000000000300', 'updated', 'Updated sprint metrics for Sprint 1', '2024-01-14 17:00:00');

-- =====================================================
-- END OF SAMPLE DATA
-- =====================================================
