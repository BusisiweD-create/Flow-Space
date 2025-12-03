# Core API Endpoints
## Essential Endpoints for Deliverable & Sprint Sign-Off Hub

This document lists the **essential API endpoints** needed to support the core functionality of your application.

## Base URL: `http://localhost:3000/api`

---

## 🔐 AUTHENTICATION (Required for all screens)

```
POST /auth/login          # User login
POST /auth/register       # User registration  
GET  /auth/me            # Get current user
POST /auth/logout        # User logout
```

---

## 📊 DASHBOARD SCREEN

```
GET  /dashboard/stats           # Dashboard statistics
GET  /deliverables/recent       # Recent deliverables
GET  /sprints/active           # Active sprints
GET  /notifications/unread     # Unread notifications
```

---

## 🎯 ENHANCED DELIVERABLE SETUP SCREEN

```
POST /deliverables                    # Create deliverable
GET  /deliverables/:id               # Get deliverable details
PUT  /deliverables/:id               # Update deliverable

POST /deliverables/:id/dod-items     # Add DoD item
PUT  /dod-items/:id                 # Update DoD item
DELETE /dod-items/:id               # Delete DoD item

POST /deliverables/:id/evidence     # Add evidence link
PUT  /evidence/:id                  # Update evidence link
DELETE /evidence/:id                # Delete evidence link

GET  /deliverables/:id/readiness    # Get readiness check
POST /deliverables/:id/readiness    # Create/update readiness check
```

---

## 📈 SPRINT METRICS SCREEN

```
GET  /sprints/:id/metrics           # Get sprint metrics
POST /sprints/:id/metrics           # Create/update metrics
PUT  /sprint-metrics/:id            # Update metrics
GET  /sprints/:id                   # Get sprint details
```

---

## 📝 REPORT BUILDER SCREEN

```
POST /reports                       # Create report
GET  /reports/:id                   # Get report details
PUT  /reports/:id                   # Update report
POST /reports/:id/generate          # Auto-generate content
GET  /reports/:id/preview           # Get formatted preview
POST /reports/:id/submit            # Submit for review
```

---

## 👥 CLIENT REVIEW SCREEN

```
GET  /reports/:id/review            # Get review data
POST /reports/:id/review            # Submit review decision
GET  /client-reviews                # Get client reviews
PUT  /client-reviews/:id            # Update review
```

---

## 🔔 NOTIFICATION CENTER SCREEN

```
GET  /notifications                 # Get user notifications
PUT  /notifications/:id/read       # Mark as read
PUT  /notifications/read-all       # Mark all as read
DELETE /notifications/:id          # Delete notification
```

---

## 📁 REPORT REPOSITORY SCREEN

```
GET  /reports                       # Get all reports
GET  /reports/search               # Search reports
GET  /reports/:id                  # Get report details
GET  /reports/:id/export/pdf       # Export as PDF
```

---

## 🏗️ PROJECT & SPRINT MANAGEMENT

```
GET  /projects                     # Get user projects
POST /projects                     # Create project
GET  /projects/:id/sprints         # Get project sprints
POST /projects/:id/sprints         # Create sprint
```

---

## 📊 ANALYTICS & DASHBOARD DATA

```
GET  /analytics/dashboard          # Dashboard metrics
GET  /analytics/sprint-performance # Sprint analytics
GET  /analytics/deliverable-status # Deliverable status
```

---

## 🔍 SEARCH & FILTERING

```
GET  /search/deliverables          # Search deliverables
GET  /search/reports               # Search reports
GET  /search/sprints               # Search sprints
```

---

## 📋 SAMPLE REQUEST/RESPONSE

### Create Deliverable
```http
POST /api/deliverables
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "User Authentication System",
  "description": "Complete user login and registration system",
  "dueDate": "2024-02-15",
  "assignedTo": "user-uuid",
  "sprintIds": ["sprint-uuid-1", "sprint-uuid-2"]
}
```

### Response
```json
{
  "success": true,
  "data": {
    "id": "deliverable-uuid",
    "title": "User Authentication System",
    "status": "draft",
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

### Submit Sprint Metrics
```http
POST /api/sprints/sprint-uuid/metrics
Content-Type: application/json
Authorization: Bearer <token>

{
  "committedPoints": 20,
  "completedPoints": 18,
  "testPassRate": 95.5,
  "defectsOpened": 3,
  "defectsClosed": 3
}
```

### Create Sign-Off Report
```http
POST /api/reports
Content-Type: application/json
Authorization: Bearer <token>

{
  "deliverableId": "deliverable-uuid",
  "reportTitle": "Sign-Off Report: User Authentication System",
  "reportContent": "## Executive Summary...",
  "knownLimitations": "MFA setup requires admin configuration"
}
```

---

## 🚀 IMPLEMENTATION PRIORITY

### Phase 1: Core Functionality
1. **Authentication** - Login/register
2. **Deliverable Management** - CRUD operations
3. **Sprint Metrics** - Data capture
4. **Basic Reports** - Create and view

### Phase 2: Advanced Features
1. **Release Readiness** - Validation system
2. **Client Review** - Approval workflow
3. **Notifications** - Real-time alerts
4. **Search & Filtering** - Enhanced UX

### Phase 3: Analytics & Export
1. **Dashboard Analytics** - Performance metrics
2. **Export Functions** - PDF/Word generation
3. **Bulk Operations** - Mass updates
4. **Advanced Reporting** - Custom reports

---

## 🔧 TECHNICAL REQUIREMENTS

### Authentication
- JWT tokens with 24-hour expiration
- Refresh token mechanism
- Role-based access control

### Data Validation
- Input sanitization
- Required field validation
- Business rule enforcement

### Error Handling
- Consistent error response format
- Proper HTTP status codes
- Detailed error messages

### Performance
- Database indexing
- Query optimization
- Response caching where appropriate

---

This focused API specification covers all the essential endpoints needed to support your Deliverable & Sprint Sign-Off Hub application!
