# Sprint-Project Linking System

This document describes the Sprint-Project Linking functionality that allows users to associate existing or new sprints with projects for better organization and tracking.

## Features

### 1. Sprint Selection
- **Search existing sprints**: Users can search through available sprints by name
- **Multi-selection**: Select multiple sprints to link to a project
- **Create new sprints**: Directly create new sprints linked to the project
- **Real-time filtering**: Search results update as you type

### 2. Project Sprint Management
- **View linked sprints**: See all sprints associated with a project
- **Sprint statistics**: Track active, completed, and average progress
- **Unlink sprints**: Remove sprints from projects (doesn't delete them)
- **Role-based access**: Only owners and contributors can manage sprint links

### 3. Sprint Console Integration
- **Project context filtering**: Sprint visuals and outcomes filtered by project
- **Progress tracking**: Visual progress bars for each sprint
- **Status indicators**: Color-coded status badges
- **Ticket integration**: Show ticket counts and completion rates

## API Endpoints

### Get Project Sprints
```
GET /api/v1/projects/:projectId/sprints
```
Returns all sprints linked to a project with progress metrics.

### Link Sprints to Project
```
POST /api/v1/projects/:projectId/sprints
Content-Type: application/json

{
  "sprintIds": ["sprint-id-1", "sprint-id-2"]
}
```
Links multiple existing sprints to a project.

### Create New Sprint for Project
```
POST /api/v1/projects/:projectId/sprints/new
Content-Type: application/json

{
  "name": "Sprint Name",
  "description": "Optional description",
  "start_date": "2024-01-01",
  "end_date": "2024-01-14"
}
```
Creates a new sprint directly linked to the project.

### Unlink Sprint from Project
```
DELETE /api/v1/projects/:projectId/sprints/:sprintId
```
Removes a sprint from a project (sets project_id to null).

### Get Available Sprints
```
GET /api/v1/projects/:projectId/available-sprints?search=query
```
Returns sprints that can be linked to the project (not already linked).

## Database Schema

### Sprints Table
```sql
CREATE TABLE sprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    status VARCHAR(50) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Audit Logs
All sprint linking actions are logged in the `audit_logs` table:
- `link_sprint_to_project`: When a sprint is linked to a project
- `unlink_sprint_from_project`: When a sprint is unlinked
- `create_sprint_for_project`: When a new sprint is created for a project

## Frontend Components

### SprintSelector Widget
A reusable widget for selecting and creating sprints:
- Search functionality
- Multi-selection with checkboxes
- Create new sprint form
- Real-time validation

### ProjectSprintManagementScreen
Main screen for managing project sprints:
- Display linked sprints with progress
- Sprint statistics dashboard
- Unlink functionality
- Role-based access control

### ProjectSprintService
Service class for API interactions:
- Error handling
- Response formatting
- Helper methods for status/date formatting

## Permission System

### Project Roles
- **Owner**: Full access to manage sprint links
- **Contributor**: Can link/unlink sprints
- **Viewer**: Read-only access to linked sprints

### System Roles
- **systemAdmin**: Full access to all projects
- **projectManager**: Can manage sprints in their projects
- **deliveryLead**: Can manage sprints in their projects
- **teamMember**: Limited to their own sprints
- **clientReviewer**: Read-only access

## Sprint Status Flow

```
draft → active → completed
  ↓        ↓
cancelled  (can be cancelled at any time)
```

### Status Colors
- **Draft**: Orange (#FF9800)
- **Active**: Green (#4CAF50)
- **Completed**: Blue (#2196F3)
- **Cancelled**: Red (#F44336)

## Progress Calculation

Progress is calculated based on:
1. **Points-based**: If sprint has story points
2. **Ticket-based**: If no points, uses ticket completion rate
3. **Default**: 0% if no metrics available

### Progress Colors
- **80%+**: Green
- **50-79%**: Orange
- **20-49%**: Amber
- **<20%**: Red

## Testing

### Backend Tests
Run the test script to verify functionality:
```bash
cd backend
node test-sprint-linking.js
```

### Test Coverage
- ✅ Database schema validation
- ✅ Sprint linking operations
- ✅ Sprint creation for projects
- ✅ Sprint unlinking
- ✅ Audit logging
- ✅ Permission checks

## Usage Examples

### Linking Existing Sprints
```dart
final result = await ProjectSprintService.linkSprintsToProject(
  projectId,
  ['sprint-id-1', 'sprint-id-2'],
);
```

### Creating New Sprint
```dart
final newSprint = await ProjectSprintService.createSprintForProject(
  projectId,
  'Sprint 1',
  description: 'First sprint for the project',
  startDate: '2024-01-01',
  endDate: '2024-01-14',
);
```

### Getting Project Sprints
```dart
final sprints = await ProjectSprintService.getProjectSprints(projectId);
```

## Integration Points

### Sprint Console
- Filter sprints by project context
- Show project-specific metrics
- Display linked deliverables and tickets

### Dashboard
- Project sprint overview
- Progress summaries
- Active sprint indicators

### Project Management
- Sprint management tab
- Link/unlink operations
- Sprint statistics

## Error Handling

### Common Errors
- **403 Forbidden**: User lacks permission
- **404 Not Found**: Sprint or project not found
- **400 Bad Request**: Invalid sprint data
- **500 Server Error**: Database or API error

### Error Messages
- "Only project owners and contributors can link sprints"
- "Sprint name is required"
- "Sprint not found in this project"

## Performance Considerations

### Database Indexes
- `idx_sprints_project`: For fast project-based queries
- `idx_sprints_dates`: For date-based filtering
- `idx_sprints_status`: For status-based queries

### Caching
- Sprint data cached per project
- Progress calculations cached
- Search results cached temporarily

## Future Enhancements

### Planned Features
- Sprint templates
- Bulk operations
- Sprint cloning
- Advanced filtering
- Sprint dependencies
- Time tracking integration

### UI Improvements
- Drag-and-drop sprint ordering
- Sprint timeline view
- Kanban-style board
- Sprint calendar view
- Advanced search filters

## Troubleshooting

### Common Issues
1. **Sprints not appearing**: Check project permissions
2. **Progress not updating**: Verify ticket completion status
3. **Search not working**: Check network connectivity
4. **Can't unlink sprint**: Verify user role and permissions

### Debug Information
- Check browser console for errors
- Verify API responses in network tab
- Check database for proper project_id values
- Review audit logs for action tracking

## Support

For issues or questions:
1. Check the test script output
2. Review API response codes
3. Verify user permissions
4. Check database schema
5. Review frontend console logs
