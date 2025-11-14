# Flow-Space Backend Database Setup

This directory contains the database schema and setup scripts for the Flow-Space role-based system.

## 📁 Files Overview

### Database Schema
- **`database/schema.sql`** - Complete database schema with all tables, indexes, and triggers
- **`database/seed_data.sql`** - Initial data including roles and permissions

### Setup Scripts
- **`setup-database.js`** - Main database setup script
- **`test-database.js`** - Database connection and data verification script
- **`setup.sh`** - Unix/Linux/macOS setup script
- **`setup.bat`** - Windows setup script

### Server Files
- **`server-updated.js`** - Updated server with role-based authentication
- **`server.js`** - Original server (legacy)

## 🗄️ Database Schema

### Core Tables

#### Users & Authentication
- **`users`** - User accounts with role information
- **`user_roles`** - Available user roles (Team Member, Delivery Lead, etc.)
- **`permissions`** - System permissions
- **`role_permissions`** - Role-permission mappings

#### Project Management
- **`projects`** - Project information
- **`project_members`** - Project team members
- **`deliverables`** - Project deliverables
- **`sprints`** - Sprint information
- **`sprint_deliverables`** - Sprint-deliverable relationships

#### Review & Approval
- **`sign_off_reports`** - Deliverable sign-off reports
- **`client_reviews`** - Client review records

#### System Features
- **`notifications`** - User notifications
- **`audit_logs`** - System audit trail

### Key Features

#### Role-Based Access Control
- 4 user roles: Team Member, Delivery Lead, Client Reviewer, System Admin
- 15+ permissions for granular access control
- Automatic role-permission mapping

#### Data Integrity
- UUID primary keys for all entities
- Foreign key constraints
- Automatic timestamp updates
- JSONB fields for flexible data storage

#### Performance
- Optimized indexes for common queries
- Efficient role-based filtering
- Audit trail for security

## 🚀 Quick Setup

### Prerequisites
- Node.js (v14 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

### Backend Migration (Python → Node.js)
The backend has been migrated from Python to Node.js for better performance and maintainability. The new Node.js backend is located in the `node-backend/` directory.

### Node.js Backend Setup
```bash
# Navigate to Node.js backend directory
cd node-backend

# Install dependencies
npm install

# Start the server
npm start

# For development with auto-reload
npm run dev
```

### Windows Setup (Legacy Python Backend)
```bash
# Run the setup script (for legacy Python backend)
setup.bat
```

### Unix/Linux/macOS Setup (Legacy Python Backend)
```bash
# Make script executable
chmod +x setup.sh

# Run the setup script (for legacy Python backend)
./setup.sh
```

### Manual Setup (Legacy Python Backend)
```bash
# Install dependencies
npm install

# Setup database
node setup-database.js

# Test database
node test-database.js

# Start server (legacy)
node server-updated.js
```

## 🔧 Configuration

### Database Configuration
Update `database-config.js` with your PostgreSQL settings:

```javascript
const config = {
  local: {
    user: 'postgres',
    host: 'localhost',
    database: 'flow_space',
    password: 'your_password',
    port: 5432,
  }
};
```

### Environment Variables
Set these environment variables for production:

```bash
NODE_ENV=production
JWT_SECRET=your-secure-jwt-secret
DB_HOST=your-db-host
DB_USER=your-db-user
DB_PASSWORD=your-db-password
DB_NAME=flow_space
```

## 📊 API Endpoints

### Node.js Backend (Current)
The Node.js backend runs on port **8000** and provides the following endpoints:

#### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login  
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/change-password` - Change password

#### User Management (Admin)
- `GET /api/v1/users` - List all users
- `PUT /api/v1/users/:userId/role` - Change user role

#### Deliverables
- `GET /api/v1/deliverables` - List deliverables (role-filtered)

#### System
- `GET /health` - Health check endpoint

### Legacy Python Backend
**Note:** The Python backend is deprecated and should not be used for new development. It ran on port **3000**.

## 🧪 Testing

### Node.js Backend Testing

#### Health Check
```bash
curl http://localhost:8000/health
```

#### User Registration
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","first_name":"Test","last_name":"User","role":"teamMember"}'
```

#### User Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Legacy Python Backend Testing

#### Database Test
```bash
node test-database.js
```

#### API Testing
```bash
# Health check
curl http://localhost:3000/health

# Register user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User","role":"teamMember"}'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🔐 Security Features

### Authentication
- JWT-based authentication
- Password hashing with bcrypt
- Token expiration (24 hours)

### Authorization
- Role-based access control
- Permission-based endpoint protection
- Admin-only user management

### Audit Trail
- Complete audit logging
- User action tracking
- Security event monitoring

## 📈 Performance

### Database Optimization
- Strategic indexing for common queries
- Efficient role-based filtering
- JSONB for flexible data storage

### Caching
- JWT token caching
- Role permission caching
- Query result optimization

## 🛠️ Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
# Check PostgreSQL status
pg_isready

# Check database exists
psql -l | grep flow_space
```

#### Permission Denied
```bash
# Check PostgreSQL user permissions
psql -U postgres -c "SELECT * FROM pg_user;"
```

#### Port Already in Use
```bash
# Check port 3000
netstat -an | grep :3000

# Kill process using port
lsof -ti:3000 | xargs kill -9
```

### Logs
- Server logs: Console output
- Database logs: PostgreSQL logs
- Audit logs: `audit_logs` table

## 📚 Schema Documentation

### User Roles
1. **Team Member** - Create deliverables, view own work
2. **Delivery Lead** - Manage team, submit for review
3. **Client Reviewer** - Review and approve deliverables
4. **System Admin** - Full system access

### Permissions
- `create_deliverable` - Create new deliverables
- `edit_deliverable` - Edit existing deliverables
- `submit_for_review` - Submit for client review
- `approve_deliverable` - Approve deliverables
- `manage_users` - Manage user accounts
- And 10+ more permissions...

## 🔄 Maintenance

### Database Backup
```bash
# Backup database
pg_dump flow_space > backup.sql

# Restore database
psql flow_space < backup.sql
```

### Updates
```bash
# Update schema
node setup-database.js

# Verify updates
node test-database.js
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the logs
3. Test database connectivity
4. Verify configuration settings

---

**Flow-Space Backend Database** - Role-based project management system with PostgreSQL and Node.js
