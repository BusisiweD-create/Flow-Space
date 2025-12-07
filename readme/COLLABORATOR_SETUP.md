# 🤝 Database Connection Info for Collaborators 

## Database Connection Details 

Your collaborators can connect to the shared PostgreSQL database using these details:

### Connection Information:
- **Host**: 172.19.48.1
- **Port**: 5432
- **Database**: flow_space
- **Username**: flowspace_user
- **Password**: FlowSpace2024!

## Setup Instructions for Collaborators

### Step 1: Clone the Repository
```bash
git clone <repository-url>
cd Flow
```

### Step 2: Set Up Python Environment
```bash
# Navigate to backend
cd backend/hackathon-backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 3: Environment Configuration
The `.env` file is already configured with the correct database connection:
```env
DATABASE_URL=postgresql://flowspace_user:FlowSpace2024!@172.19.48.1:5432/flow_space
NODE_ENV=shared
```

### Step 4: Test Database Connection
```bash
# Test PostgreSQL connection
psql -h 172.19.48.1 -U flowspace_user -d flow_space
# Password: FlowSpace2024!
```

### Step 5: Start the Backend Server
```bash
# Start FastAPI backend with hot reload
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Step 6: Start the Flutter Frontend
```bash
# Open new terminal and navigate to frontend
cd frontend

# Install Flutter dependencies
flutter pub get

# Run the application
flutter run
```

## Important Notes

1. **Network Access Required**: Collaborators must be on the same network as you
2. **Firewall**: Make sure port 5432 (PostgreSQL) and 8000 (backend) are open
3. **PostgreSQL Config**: Ensure PostgreSQL accepts external connections
4. **Python Version**: Requires Python 3.8+ 
5. **Flutter**: Requires Flutter SDK installed

## Troubleshooting

### Connection Issues
- **Connection Refused**: Check if PostgreSQL is running and firewall settings
- **Authentication Failed**: Verify username/password
- **Database Not Found**: Ensure database exists and user has access

### Python Environment Issues
```bash
# If you encounter package conflicts
pip install --upgrade -r requirements.txt

# If database migrations are needed
# Check the alembic directory for migration scripts
```

### Flutter Issues
```bash
# Clean and rebuild if needed
flutter clean
flutter pub get
flutter run
```

## API Endpoints
- Backend API: http://localhost:8000
- API Documentation: http://localhost:8000/docs (Swagger UI)
- Database Admin: Consider using pgAdmin or similar tool

## Your IP Address: 172.19.48.1

---

Share this information with your collaborators! 🚀