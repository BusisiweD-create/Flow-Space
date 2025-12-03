# Repository & Audit Feature Analysis

## Use Case Requirements:
1. ✅ Repository of all signed reports and their history
2. ❌ Track who submitted, who viewed, who approved/declined, when
3. ❌ Search by project, sprint, deliverable, or timeframe

## Current Implementation Status:

### ✅ **Backend (Implemented)**
- `/api/v1/documents/:id/audit` - Get document audit history ✅
- `/api/v1/repository/audit` - Get repository audit with filters (projectId, sprintId, deliverableId, from, to) ✅
- `audit_logs` table exists with columns: user_id, action, resource_type, resource_id, details, created_at ✅
- Document upload/download/delete actions are logged ✅

### ✅ **Frontend Services (Implemented)**
- `DocumentService.getDocumentAudit(documentId)` ✅
- `DocumentService.getRepositoryAudit({projectId, sprintId, deliverableId, from, to})` ✅
- Basic document search by name/description/tags ✅

### ❌ **Missing Features**

#### 1. **Sign-Off Reports Backend API**
- ❌ No GET `/api/v1/sign-off-reports` endpoint
- ❌ No GET `/api/v1/sign-off-reports/:id` endpoint
- ❌ No tracking of report submissions/approvals/declines in audit_logs
- ❌ No integration between sign_off_reports table and audit_logs

#### 2. **Report View Tracking**
- ❌ No tracking of who viewed reports (only uploads/downloads/deletes tracked)
- ❌ No audit log entry when user views a report

#### 3. **Audit History UI**
- ❌ No UI component to display audit history
- ❌ Repository screen doesn't show audit logs
- ❌ Report repository screen doesn't show audit logs
- ❌ No timeline view of who did what and when

#### 4. **Search & Filter UI**
- ❌ Repository screen doesn't have project filter
- ❌ Repository screen doesn't have sprint filter  
- ❌ Repository screen doesn't have deliverable filter
- ❌ Repository screen doesn't have timeframe/date range filter
- ❌ Report repository screen uses MOCK DATA (not real API)

#### 5. **Sign-Off Reports Integration**
- ❌ Report repository screen uses hardcoded mock data
- ❌ No connection to real sign-off reports from database
- ❌ No API endpoints for sign-off reports in backend

## Recommendations:

### Priority 1 (Critical):
1. Create backend API endpoints for sign-off reports
2. Add audit logging for report views
3. Replace mock data in report_repository_screen.dart with real API calls

### Priority 2 (Important):
4. Create audit history UI component
5. Add filtering UI (project, sprint, deliverable, timeframe)
6. Integrate sign-off reports with audit logs

### Priority 3 (Enhancement):
7. Add timeline view for audit history
8. Add export functionality for audit logs
9. Add email notifications for audit events

