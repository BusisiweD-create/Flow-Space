# Database Setup Guide
## Deliverable & Sprint Sign-Off Hub

This guide provides step-by-step instructions for setting up the database for the Deliverable & Sprint Sign-Off Hub application.

## Prerequisites

- PostgreSQL 12+ or compatible database
- Database user with CREATE privileges
- Basic knowledge of SQL

## Quick Setup

### Option 1: Complete Schema (Recommended for Production)

```bash
# Run the complete schema
psql -d your_database -f database_schema_complete.sql

# Add sample data for testing
psql -d your_database -f database_sample_data.sql
```

### Option 2: Incremental Migrations (Recommended for Development)

```bash
# Run migrations in order
psql -d your_database -f database_migrations.sql

# Add sample data for testing
psql -d your_database -f database_sample_data.sql
```

## Database Schema Overview

### Core Tables

#### 1. User Management
- `users` - User accounts and authentication
- `user_sessions` - Active user sessions
- `project_members` - Project team memberships

#### 2. Project Management
- `projects` - Project definitions
- `sprints` - Sprint planning and tracking
- `sprint_metrics` - Sprint performance data

#### 3. Deliverable Management
- `deliverables` - Deliverable definitions
- `deliverable_dod_items` - Definition of Done checklist
- `deliverable_evidence` - Evidence links and artifacts
- `deliverable_sprints` - Sprint-deliverable relationships

#### 4. Release Readiness
- `release_readiness_checks` - Readiness validation
- `readiness_items` - Individual readiness criteria

#### 5. Sign-Off Reports
- `sign_off_reports` - Generated reports
- `report_sprints` - Report-sprint relationships
- `client_reviews` - Client review decisions

#### 6. Notifications & Audit
- `notifications` - System notifications
- `activity_logs` - Audit trail
- `repository_files` - File management
- `approval_requests` - Approval workflows

## Key Features Supported

### 1. Enhanced Deliverable Setup Screen
- ✅ DoD checklist management
- ✅ Evidence attachment system
- ✅ Release readiness validation
- ✅ Sprint association

### 2. Sprint Metrics Screen
- ✅ Comprehensive metrics capture
- ✅ Quality indicators tracking
- ✅ Risk and mitigation notes
- ✅ Process metrics

### 3. Report Builder Screen
- ✅ Auto-generated report content
- ✅ Sprint performance visualization
- ✅ Professional formatting
- ✅ Preview and edit capabilities

### 4. Client Review Screen
- ✅ Secure review interface
- ✅ Approve/Change Request workflow
- ✅ Digital signature capture
- ✅ Priority and reminder management

### 5. Notification Center
- ✅ Priority-based notifications
- ✅ Type-based filtering
- ✅ Read/unread status tracking
- ✅ Smart navigation

### 6. Report Repository
- ✅ Complete report management
- ✅ Search and filtering
- ✅ Status tracking
- ✅ Digital signature verification

## Database Views

### 1. `deliverable_summary`
Provides comprehensive deliverable information including sprint count, DoD items, and evidence.

### 2. `sprint_performance_summary`
Shows sprint performance metrics with quality status indicators.

### 3. `notification_summary`
Displays notification information with user details.

## Indexes for Performance

The schema includes optimized indexes for:
- User lookups by email and role
- Project and sprint queries
- Deliverable status filtering
- Notification management
- Activity log queries

## Sample Data

The `database_sample_data.sql` file includes:
- 6 sample users with different roles
- 3 sample projects
- 5 sample sprints with metrics
- 3 sample deliverables with DoD items
- 1 complete sign-off report
- Sample notifications and activity logs

## Security Considerations

1. **Password Hashing**: Use bcrypt or similar for password storage
2. **Session Management**: Implement proper session expiration
3. **Access Control**: Use row-level security for multi-tenant data
4. **Audit Trail**: All changes are logged in `activity_logs`

## Performance Optimization

1. **Indexes**: Comprehensive indexing for common queries
2. **Triggers**: Automatic timestamp updates
3. **Views**: Pre-computed summaries for dashboard queries
4. **Partitioning**: Consider partitioning large tables by date

## Backup and Recovery

```bash
# Create backup
pg_dump -h localhost -U username -d database_name > backup.sql

# Restore backup
psql -h localhost -U username -d database_name < backup.sql
```

## Monitoring and Maintenance

1. **Regular VACUUM**: Keep tables optimized
2. **Index Maintenance**: Monitor index usage
3. **Query Performance**: Use EXPLAIN ANALYZE for slow queries
4. **Log Analysis**: Monitor activity_logs for system usage

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure database user has CREATE privileges
2. **Foreign Key Violations**: Check that referenced records exist
3. **Index Conflicts**: Drop existing indexes before recreating
4. **Trigger Errors**: Ensure functions are created before triggers

### Useful Queries

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('your_database'));

-- Check table sizes
SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables WHERE schemaname = 'public';

-- Check active connections
SELECT count(*) FROM pg_stat_activity;
```

## Support

For database-related issues:
1. Check PostgreSQL logs
2. Verify user permissions
3. Test with sample data
4. Review foreign key constraints

## Next Steps

After database setup:
1. Configure application connection strings
2. Test all CRUD operations
3. Set up monitoring
4. Plan backup strategy
5. Configure user roles and permissions
