# API Endpoints Specification
## Deliverable & Sprint Sign-Off Hub

This document outlines all the API endpoints needed to support the complete Deliverable & Sprint Sign-Off Hub application.

## Base URL
```
http://localhost:3000/api
```

## Authentication
All endpoints (except auth) require a valid JWT token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

---

## 1. AUTHENTICATION ENDPOINTS

### POST /auth/register
Register a new user
```json
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "company": "TechCorp",
  "role": "project_manager"
}
```

### POST /auth/login
Login user
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### POST /auth/logout
Logout user (invalidate token)

### POST /auth/refresh
Refresh JWT token

### GET /auth/me
Get current user profile

---

## 2. USER MANAGEMENT ENDPOINTS

### GET /users
Get all users (admin only)
- Query params: `role`, `active`, `search`

### GET /users/:id
Get user by ID

### PUT /users/:id
Update user profile
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "company": "TechCorp",
  "role": "project_manager"
}
```

### DELETE /users/:id
Delete user (admin only)

---

## 3. PROJECT MANAGEMENT ENDPOINTS

### GET /projects
Get user's projects
- Query params: `status`, `search`

### POST /projects
Create new project
```json
{
  "name": "Authentication System",
  "description": "User authentication and authorization system",
  "startDate": "2024-01-01",
  "endDate": "2024-03-31"
}
```

### GET /projects/:id
Get project details

### PUT /projects/:id
Update project
```json
{
  "name": "Updated Project Name",
  "description": "Updated description",
  "status": "active"
}
```

### DELETE /projects/:id
Delete project

### POST /projects/:id/members
Add project member
```json
{
  "userId": "user-uuid",
  "role": "member"
}
```

### DELETE /projects/:id/members/:userId
Remove project member

---

## 4. SPRINT MANAGEMENT ENDPOINTS

### GET /projects/:projectId/sprints
Get project sprints
- Query params: `status`, `dateRange`

### POST /projects/:projectId/sprints
Create new sprint
```json
{
  "name": "Sprint 1 - Foundation",
  "description": "Basic authentication setup",
  "startDate": "2024-01-01",
  "endDate": "2024-01-14"
}
```

### GET /sprints/:id
Get sprint details

### PUT /sprints/:id
Update sprint
```json
{
  "name": "Updated Sprint Name",
  "status": "active"
}
```

### DELETE /sprints/:id
Delete sprint

---

## 5. SPRINT METRICS ENDPOINTS

### GET /sprints/:sprintId/metrics
Get sprint metrics

### POST /sprints/:sprintId/metrics
Create/update sprint metrics
```json
{
  "committedPoints": 20,
  "completedPoints": 18,
  "carriedOverPoints": 2,
  "testPassRate": 95.5,
  "defectsOpened": 3,
  "defectsClosed": 3,
  "criticalDefects": 0,
  "highDefects": 1,
  "mediumDefects": 1,
  "lowDefects": 1,
  "codeReviewCompletion": 100.0,
  "documentationStatus": 85.0,
  "risks": "Initial authentication complexity",
  "mitigations": "Extended testing phase",
  "scopeChanges": "Added MFA requirement",
  "uatNotes": "Client feedback incorporated"
}
```

### PUT /sprint-metrics/:id
Update sprint metrics

### DELETE /sprint-metrics/:id
Delete sprint metrics

---

## 6. DELIVERABLE MANAGEMENT ENDPOINTS

### GET /projects/:projectId/deliverables
Get project deliverables
- Query params: `status`, `assignedTo`, `dueDate`

### POST /projects/:projectId/deliverables
Create new deliverable
```json
{
  "title": "User Authentication System",
  "description": "Complete user login and registration system",
  "dueDate": "2024-02-15",
  "assignedTo": "user-uuid",
  "sprintIds": ["sprint-uuid-1", "sprint-uuid-2"]
}
```

### GET /deliverables/:id
Get deliverable details

### PUT /deliverables/:id
Update deliverable
```json
{
  "title": "Updated Title",
  "description": "Updated description",
  "status": "submitted"
}
```

### DELETE /deliverables/:id
Delete deliverable

### POST /deliverables/:id/submit
Submit deliverable for review

### POST /deliverables/:id/approve
Approve deliverable
```json
{
  "comment": "Approved with minor suggestions"
}
```

### POST /deliverables/:id/reject
Reject deliverable
```json
{
  "reason": "Missing test coverage",
  "changeRequestDetails": "Please add more unit tests"
}
```

---

## 7. DEFINITION OF DONE ENDPOINTS

### GET /deliverables/:id/dod-items
Get DoD items for deliverable

### POST /deliverables/:id/dod-items
Add DoD item
```json
{
  "itemText": "All unit tests pass with >90% coverage"
}
```

### PUT /dod-items/:id
Update DoD item
```json
{
  "itemText": "Updated DoD item",
  "isCompleted": true
}
```

### DELETE /dod-items/:id
Delete DoD item

---

## 8. EVIDENCE MANAGEMENT ENDPOINTS

### GET /deliverables/:id/evidence
Get evidence links for deliverable

### POST /deliverables/:id/evidence
Add evidence link
```json
{
  "linkUrl": "https://demo.example.com/auth",
  "linkType": "demo",
  "description": "Live demo environment"
}
```

### PUT /evidence/:id
Update evidence link

### DELETE /evidence/:id
Delete evidence link

---

## 9. RELEASE READINESS ENDPOINTS

### GET /deliverables/:id/readiness-check
Get release readiness check

### POST /deliverables/:id/readiness-check
Create/update readiness check
```json
{
  "status": "green",
  "items": [
    {
      "category": "Definition of Done",
      "description": "All DoD items are completed",
      "isRequired": true,
      "isCompleted": true
    }
  ]
}
```

### POST /readiness-checks/:id/approve
Approve readiness check with issues
```json
{
  "approvalComment": "Approved with acknowledged limitations"
}
```

---

## 10. SIGN-OFF REPORTS ENDPOINTS

### GET /reports
Get all reports
- Query params: `status`, `deliverableId`, `createdBy`

### POST /reports
Create new report
```json
{
  "deliverableId": "deliverable-uuid",
  "reportTitle": "Sign-Off Report: User Authentication System",
  "reportContent": "## Executive Summary...",
  "knownLimitations": "MFA setup requires admin configuration",
  "nextSteps": "Deploy to production environment"
}
```

### GET /reports/:id
Get report details

### PUT /reports/:id
Update report
```json
{
  "reportTitle": "Updated Report Title",
  "reportContent": "Updated content...",
  "status": "submitted"
}
```

### POST /reports/:id/submit
Submit report for review

### POST /reports/:id/generate
Auto-generate report content
```json
{
  "includeSprintMetrics": true,
  "includeQualityIndicators": true
}
```

### GET /reports/:id/preview
Get report preview (formatted)

---

## 11. CLIENT REVIEW ENDPOINTS

### GET /reports/:id/review
Get client review interface data

### POST /reports/:id/review
Submit client review
```json
{
  "action": "approve", // or "change_request"
  "comment": "Excellent work, approved!",
  "changeRequestDetails": "Please add more documentation",
  "priority": "normal",
  "reminderDate": "2024-02-20",
  "escalationEnabled": false
}
```

### GET /client-reviews
Get client reviews
- Query params: `status`, `reviewerId`, `dateRange`

### PUT /client-reviews/:id
Update client review

---

## 12. NOTIFICATION ENDPOINTS

### GET /notifications
Get user notifications
- Query params: `type`, `priority`, `isRead`, `dateRange`

### PUT /notifications/:id/read
Mark notification as read

### PUT /notifications/read-all
Mark all notifications as read

### POST /notifications
Create notification (admin only)
```json
{
  "userId": "user-uuid",
  "title": "Deliverable Review Required",
  "message": "User Authentication System is ready for review",
  "type": "review",
  "priority": "high",
  "deliverableId": "deliverable-uuid"
}
```

### DELETE /notifications/:id
Delete notification

---

## 13. REPOSITORY ENDPOINTS

### GET /projects/:projectId/files
Get project files
- Query params: `fileType`, `search`, `dateRange`

### POST /projects/:projectId/files
Upload file
```json
{
  "fileName": "document.pdf",
  "filePath": "/uploads/document.pdf",
  "fileType": "documentation",
  "description": "User guide"
}
```

### GET /files/:id
Get file details

### DELETE /files/:id
Delete file

---

## 14. APPROVAL WORKFLOW ENDPOINTS

### GET /approvals
Get approval requests
- Query params: `status`, `entityType`, `requestedBy`

### POST /approvals
Create approval request
```json
{
  "entityType": "deliverable",
  "entityId": "deliverable-uuid",
  "comments": "Please review this deliverable"
}
```

### PUT /approvals/:id
Update approval request
```json
{
  "status": "approved", // or "rejected"
  "comments": "Approved with minor suggestions"
}
```

---

## 15. ANALYTICS & REPORTING ENDPOINTS

### GET /analytics/dashboard
Get dashboard analytics
```json
{
  "totalDeliverables": 15,
  "pendingReviews": 3,
  "completedSprints": 8,
  "averageVelocity": 18.5,
  "qualityMetrics": {
    "averageTestPassRate": 96.2,
    "defectResolutionRate": 95.8
  }
}
```

### GET /analytics/sprint-performance
Get sprint performance analytics
- Query params: `projectId`, `dateRange`

### GET /analytics/deliverable-status
Get deliverable status distribution

### GET /analytics/team-performance
Get team performance metrics

---

## 16. SEARCH ENDPOINTS

### GET /search
Global search across all entities
- Query params: `q`, `type`, `projectId`

### GET /search/deliverables
Search deliverables
- Query params: `q`, `status`, `projectId`

### GET /search/reports
Search reports
- Query params: `q`, `status`, `dateRange`

### GET /search/sprints
Search sprints
- Query params: `q`, `status`, `projectId`

---

## 17. EXPORT ENDPOINTS

### GET /reports/:id/export/pdf
Export report as PDF

### GET /reports/:id/export/docx
Export report as Word document

### GET /deliverables/:id/export
Export deliverable summary

### GET /sprints/:id/export
Export sprint metrics

---

## 18. BULK OPERATIONS ENDPOINTS

### POST /deliverables/bulk-update
Bulk update deliverables
```json
{
  "deliverableIds": ["uuid1", "uuid2"],
  "updates": {
    "status": "submitted"
  }
}
```

### POST /notifications/bulk-create
Bulk create notifications

### POST /sprints/bulk-create
Bulk create sprints

---

## 19. SYSTEM ENDPOINTS

### GET /health
Health check endpoint

### GET /version
Get API version

### GET /stats
Get system statistics (admin only)

### POST /backup
Create system backup (admin only)

---

## Response Formats

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation completed successfully"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": { ... }
  }
}
```

### Pagination Response
```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

---

## Authentication Flow

1. **Register/Login** → Get JWT token
2. **Include token** in all subsequent requests
3. **Token expires** → Use refresh endpoint
4. **Logout** → Invalidate token

## Error Codes

- `VALIDATION_ERROR` - Invalid input data
- `UNAUTHORIZED` - Invalid or missing token
- `FORBIDDEN` - Insufficient permissions
- `NOT_FOUND` - Resource not found
- `CONFLICT` - Resource already exists
- `SERVER_ERROR` - Internal server error

## Rate Limiting

- **Authentication endpoints**: 5 requests per minute
- **General endpoints**: 100 requests per minute
- **Bulk operations**: 10 requests per minute

## WebSocket Events

### Real-time Notifications
- `notification.created` - New notification
- `deliverable.updated` - Deliverable status changed
- `report.submitted` - Report submitted for review
- `review.completed` - Client review completed

---

This comprehensive API specification supports all the screens and functionality in your Deliverable & Sprint Sign-Off Hub application!
