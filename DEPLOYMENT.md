# Flow-Space Deployment Guide

This guide helps you deploy Flow-Space to production with all necessary database tables and project details functionality.

## 🚀 Quick Start

### For Windows Users:

1. **Setup Database:**
   ```powershell
   # Open PowerShell as Administrator
   cd backend\database
   psql -h localhost -p 5432 -U postgres -d flow_space -f deployment_migration.sql
   ```

2. **Deploy Flutter App:**
   ```powershell
   # From project root
   flutter build web --release
   # Copy build/web folder to your deployment location
   ```

3. **Test Project Details:**
   - Navigate to projects page
   - Click three dots on any project
   - Select "View Details"
   - Verify project information and members display correctly

### For Linux/Mac Users:

1. **Setup Database:**
   ```bash
   chmod +x deploy_database.sh
   ./deploy_database.sh
   ```

2. **Deploy Flutter App:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

## 📊 Database Setup

The deployment migration creates:

### ✅ Core Tables:
- `users` - User accounts with roles
- `projects` - Projects with all required fields
- `project_members` - Project team members
- `sprints` - Sprint management
- `deliverables` - Project deliverables
- `notifications` - User notifications
- `audit_logs` - Activity logging

### ✅ Enhanced Project Fields:
- `owner_id` - Project owner reference
- `key` - Project identifier (e.g., ACPS, CBUS)
- `client_name` - Client/company name
- `start_date` - Project start date
- `end_date` - Project end date
- `priority` - Project priority (high, medium, low)
- `project_type` - Project type (web, mobile, internal)

### ✅ Sample Data:
- **ACPS Project** with 3 team members
- **Corner Bus Project** with 3 team members
- Sample users for testing

## 🎯 Key Features Deployed

### ✅ Project Details Page:
- **Modern Dashboard UI** with header, stats, sprints, and team sections
- **Three-Dot Menu** on project cards with "View Details" and "Edit Project"
- **Error Handling** with helpful debug information
- **Member Display** showing names, emails, roles, and activities
- **Responsive Design** that works on all devices

### ✅ Project List Page:
- **Project Cards** with status indicators
- **Popup Menus** for project actions
- **Navigation** to details and edit screens
- **Clean Code** with zero lint issues

## 🔧 Configuration

### Environment Variables:
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flow_space
DB_USER=postgres

# API
API_BASE_URL=http://localhost:8000/api/v1
DEBUG_MODE=true
```

### Flutter Build:
```bash
# Development
flutter run

# Production Build
flutter build web --release

# Run tests
flutter test
flutter analyze
```

## 🧪 Testing

### Manual Testing Checklist:
- [ ] Projects load correctly from API/mock data
- [ ] Three-dot menu appears on project cards
- [ ] "View Details" navigates to project details page
- [ ] Project details show correct project information
- [ ] Team members display with names, emails, roles
- [ ] Error states show helpful information
- [ ] Navigation works correctly between screens
- [ ] Responsive design works on mobile/desktop

### Automated Testing:
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🚨 Troubleshooting

### Common Issues:

#### "Project Not Found" Error:
**Cause**: Project ID mismatch between list and details
**Solution**: Ensure mock data uses correct project IDs
**Fixed**: ✅ Updated mock data with real project IDs

#### Database Connection Issues:
**Cause**: PostgreSQL not running or wrong credentials
**Solution**: Check PostgreSQL status and connection parameters
**Command**: `pg_isready` to verify PostgreSQL is running

#### Build Errors:
**Cause**: Missing dependencies or Flutter version issues
**Solution**: Run `flutter pub get` and check Flutter version
**Command**: `flutter doctor` to check environment

#### Permission Issues:
**Cause**: Database user lacks required permissions
**Solution**: Grant proper permissions to database user
**Command**: `GRANT ALL PRIVILEGES ON DATABASE flow_space TO postgres;`

## 📱 Deployment URLs

### Local Development:
- Frontend: http://localhost:57828
- Backend API: http://localhost:8000/api/v1
- Database: postgresql://localhost:5432/flow_space

### Production:
Replace localhost with your actual domain/server IP

## 🔄 Git Workflow

### Branch Strategy:
- `main` - Production code
- `develop` - Development features
- `feature/*` - Feature branches

### Commit Convention:
```
feat: add new feature
fix: bug fixes
docs: documentation
ref: code refactoring
test: adding tests
chore: maintenance tasks
```

### Deployment Commands:
```bash
# Add changes
git add .

# Commit changes
git commit -m "feat: deploy project details with sample data"

# Push to production
git push origin main
```

## 📞 Support

### If you encounter issues:
1. Check the debug logs in the browser console
2. Verify database tables exist with correct structure
3. Ensure all migrations have been applied
4. Test with sample data provided

### Success Indicators:
✅ **Database Migration**: "Database migration completed successfully!"
✅ **Flutter Build**: "Build completed successfully"
✅ **Project Details**: Shows ACPS/Corner Bus projects with members
✅ **Error Handling**: Helpful debug information when projects not found

---

**🎉 Your Flow-Space application is now ready for deployment!**
