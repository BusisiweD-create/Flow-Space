# PostgreSQL Database Setup for Collaborators

## Database Connection Details

Your collaborators can connect to the shared PostgreSQL database using these details:

### Connection Information:
- **Host**: 172.19.48.1
- **Port**: 5432
- **Database**: flow_space
- **Username**: flowspace_user
- **Password**: FlowSpace2024!

## Setup Instructions for Collaborators

### Prerequisites
- Python 3.8+
- PostgreSQL client tools (psql)
- Git (for cloning the repository)

### Step 1: Clone the Repository
```bash
git clone <repository-url>
cd flow/backend/hackathon-backend
```

### Step 2: Install Dependencies
```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# On Windows:
.venv\\Scripts\\activate
# On macOS/Linux:
source .venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

### Step 3: Configure Environment
Edit or create the `.env` file in the backend directory:
```bash
# Database Configuration
DATABASE_URL=postgresql://flowspace_user:FlowSpace2024!@172.19.48.1:5432/flow_space
NODE_ENV=shared

# JWT Configuration
SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Email Configuration (optional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=your-email@gmail.com

# Application Configuration
DEBUG=True
ENVIRONMENT=development
```

### Step 4: Test Database Connection
```bash
# Test PostgreSQL connection from command line
psql -h 172.19.48.1 -U flowspace_user -d flow_space
# Password: FlowSpace2024!

# Test connection from Python
python -c "
import psycopg2
try:
    conn = psycopg2.connect(
        host='172.19.48.1',
        port=5432,
        database='flow_space',
        user='flowspace_user',
        password='FlowSpace2024!'
    )
    print('✅ PostgreSQL connection successful!')
    conn.close()
except Exception as e:
    print(f'❌ Connection failed: {e}')
"
```

### Step 5: Run Database Migrations (if needed)
```bash
# Initialize Alembic (if not already done)
python -m alembic init alembic

# Configure Alembic for PostgreSQL
# Edit alembic.ini and set:
sqlalchemy.url = postgresql://flowspace_user:FlowSpace2024!@172.19.48.1:5432/flow_space

# Run migrations
python -m alembic upgrade head
```

### Step 6: Start the Backend Server
```bash
# Start FastAPI server
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8001

# Or use the production command (no auto-reload)
python -m uvicorn main:app --host 0.0.0.0 --port 8001
```

## Verification Steps

### Test API Endpoints
```bash
# Health check
curl http://127.0.0.1:8001/health

# Database connection test
curl http://127.0.0.1:8001/api/v1/monitoring/health

# List deliverables (requires authentication)
curl http://127.0.0.1:8001/api/v1/deliverables
```

### Test Authentication
```bash
# Register a test user
curl -X POST http://127.0.0.1:8001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User",
    "company": "Test Company"
  }'

# Login
curl -X POST http://127.0.0.1:8001/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&username=test@example.com&password=password123"
```

## Troubleshooting

### Common Issues

1. **Connection refused**: Ensure PostgreSQL is running and accessible at 172.19.48.1:5432
2. **Authentication failed**: Verify username and password
3. **Database does not exist**: Check if the `flow_space` database exists
4. **Port blocked**: Ensure port 5432 is not blocked by firewall

### Connection Testing
```bash
# Test network connectivity
ping 172.19.48.1

# Test port accessibility
telnet 172.19.48.1 5432

# Check PostgreSQL service status
# On the server:
systemctl status postgresql
```

### Database Management
```bash
# Connect to PostgreSQL
psql -h 172.19.48.1 -U flowspace_user -d flow_space

# List databases
\l

# List tables
\dt

# Check connection info
\conninfo
```

## Support

If you encounter issues:
1. Check this documentation first
2. Verify your environment configuration
3. Test the database connection manually
4. Contact the team for support

## Backup and Recovery

### Database Backup
```bash
# Backup the database
pg_dump -h 172.19.48.1 -U flowspace_user -d flow_space > backup.sql

# Backup with compression
pg_dump -h 172.19.48.1 -U flowspace_user -d flow_space | gzip > backup.sql.gz
```

### Database Restore
```bash
# Restore from backup
psql -h 172.19.48.1 -U flowspace_user -d flow_space < backup.sql

# Restore compressed backup
gunzip -c backup.sql.gz | psql -h 172.19.48.1 -U flowspace_user -d flow_space
```