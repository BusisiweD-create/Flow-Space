# Pre-Change Analysis: Sign-off Report Client Review Feature

## Summary of Existing Implementation

### ✅ Already Implemented

1. **SignOffReport Model** (`lib/models/sign_off_report.dart`)
   - Has fields: `id`, `deliverableId`, `status`, `approvedAt`, `approvedBy`, `changeRequestDetails`, `digitalSignature`, `sprintPerformanceData`
   - Status enum includes: `draft`, `submitted`, `underReview`, `approved`, `changeRequested`, `rejected`
   - **Missing**: `updated_at` field (needs to be added to model if not present)

2. **ClientReviewScreen** (`lib/screens/client_review_screen.dart`)
   - Exists and displays report content
   - Has approve/request changes UI
   - Uses `SprintPerformanceChart` widget for visuals
   - **Missing**: Token-based route support, auto-generated performance visuals from sprint data

3. **Backend Routes** (`backend/node-backend/src/routes/signoff.js`)
   - `POST /api/signoff/:id/approve` - ✅ Exists (line 404)
   - `POST /api/signoff/:id/request-changes` - ✅ Exists (line 805) but **missing server-side validation for mandatory comment**
   - **Missing**: `POST /api/client-review-links` (create secure token)
   - **Missing**: `GET /api/client-review/:token` (token-based access)

4. **Database Schema** (`database_schema_complete.sql`)
   - `sign_off_reports` table exists with most fields (lines 198-218)
   - Has: `id`, `deliverable_id`, `status`, `approved_at`, `approved_by`, `change_request_details`, `digital_signature`, `sprint_performance_data`
   - **Missing**: `updated_at` field (may need to add)
   - **Missing**: `client_review_links` table entirely

5. **Chart Library** (`lib/widgets/sprint_performance_chart.dart`)
   - Uses `fl_chart` package (already in `pubspec.yaml`)
   - Supports: velocity, burndown, burnup, defects, test_pass_rate, scope_change, committed_vs_completed
   - **Ready to use** for performance visuals

6. **Notification System**
   - `Notification` model exists
   - `DatabaseNotificationService` handles notifications
   - Already sends notifications on change requests (line 871-879 in signoff.js)
   - **May need**: Update to notify all team members assigned to deliverable (not just creator)

7. **JWT Infrastructure** (`backend/node-backend/src/utils/authUtils.js`)
   - `createAccessToken` function exists
   - Can be used for generating secure review tokens

8. **Deliverable Model** (`lib/models/deliverable.dart`)
   - Has `DeliverableStatus` enum with `changeRequested`, `approved`, etc.
   - Has `assignedTo`, `assignedToName` fields for team member tracking

### ❌ Missing / Needs Implementation

1. **Database**
   - `client_review_links` table (token, report_id, expires_at, used, created_at)
   - OR use JWT-based approach (store token metadata in audit log or separate table)

2. **Backend Endpoints**
   - `POST /api/client-review-links` - Generate secure token for client review
   - `GET /api/client-review/:token` - Fetch report via token (read-only, no auth required)
   - Update `POST /api/sign-off-reports/:id/request-changes` to **enforce mandatory comment** on server

3. **Performance Visuals Auto-Generation**
   - Backend service to aggregate sprint data and generate performance metrics JSON
   - Include: velocity trend, committed vs completed, burndown/burnup, defect curve, test pass rate, scope change indicators

4. **Frontend**
   - Update `ClientReviewScreen` to accept token parameter from route
   - Fetch report via token endpoint when token provided
   - Ensure all performance visuals render correctly
   - Add error handling for expired/invalid tokens

5. **Tests**
   - Backend unit/integration tests for new endpoints
   - Frontend widget tests for client review workflow

## Files to Modify

### Backend Files
1. `backend/node-backend/src/routes/signoff.js`
   - Add `POST /api/client-review-links` endpoint
   - Add `GET /api/client-review/:token` endpoint
   - Update `POST /api/signoff/:id/request-changes` to validate mandatory comment

2. `backend/node-backend/src/routes/deliverables.js` (if exists) OR create new service
   - Add function to generate performance metrics from sprint data

3. `backend/node-backend/src/models/index.js` (if using Sequelize)
   - Add `ClientReviewLink` model (if using table approach)

4. Database migration file (new)
   - `migrations/add_client_review_links_table.sql` OR add to existing migration

### Frontend Files
1. `lib/screens/client_review_screen.dart`
   - Add token parameter support
   - Update API calls to use token endpoint when token provided
   - Ensure performance visuals render from auto-generated data

2. `lib/services/backend_api_service.dart`
   - Add `getClientReviewByToken(String token)` method
   - Add `createClientReviewLink(String reportId, String clientEmail, int expiresInSeconds)` method

3. `lib/main.dart` (routing)
   - Add route for `/client-review/:token` if not exists

### Test Files
1. `backend/node-backend/test/routes/signoff.test.js` (new or update)
   - Test token generation
   - Test token-based access
   - Test approve/request-changes with validation

2. `test/client_review_screen_test.dart` (new)
   - Test token-based access
   - Test approve workflow
   - Test request-changes with mandatory comment

## Files to Create

1. `migrations/add_client_review_links_table.sql` - Database migration
2. `backend/node-backend/src/services/performanceMetricsService.js` - Auto-generate performance visuals
3. `backend/node-backend/test/routes/client_review.test.js` - Backend tests
4. `test/client_review_screen_test.dart` - Frontend tests

## Implementation Strategy

1. **Token Approach**: Use JWT tokens with embedded report_id and expiration, store metadata in audit log for single-use tracking (simpler than separate table)
2. **Performance Metrics**: Query sprint data from database, aggregate into JSON structure expected by frontend charts
3. **Validation**: Add server-side validation for mandatory comment in request-changes endpoint
4. **Notifications**: Update existing notification logic to notify all team members assigned to deliverable (query deliverable.assignedTo and related team members)

## Domain Model Inferences

- **Deliverable Status**: Uses `DeliverableStatus` enum. On approve → set to `approved` (or `signedOff`). On request changes → set to `changeRequested` (or `inProgress`).
- **Report Status**: Uses `ReportStatus` enum. On approve → `approved`. On request changes → `changeRequested`.
- **Timestamps**: All stored in UTC (PostgreSQL TIMESTAMP), converted to local in frontend for display.

