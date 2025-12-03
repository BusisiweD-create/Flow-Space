# 🚀 Quick Start Guide - Backend Server

## Prerequisites Checklist
- ✅ Node.js installed (v14+)
- ✅ PostgreSQL running (port 5432)
- ✅ Database `flow_space` created

## Step-by-Step Instructions

### Step 1: Navigate to Backend Directory
```powershell
cd backend
```

### Step 2: Install Dependencies (if not already installed)
```powershell
npm install
```

### Step 3: Verify Database Setup
The database should already be set up, but if you need to create tables:
```powershell
node create-tables.js
```

Or use the simple setup:
```powershell
node simple-database-setup.js
```

### Step 4: Test Database Connection (Optional)
```powershell
node test-database.js
```

### Step 5: Start the Server

**Option A: Using PowerShell Script (Recommended)**
```powershell
.\start-server.ps1
```

**Option B: Using Batch File**
```powershell
.\start-server.bat
```

**Option C: Direct Node Command**
```powershell
node server.js
```

### Step 6: Verify Server is Running
You should see:
```
Flow-Space API server running on port 3001
Connected to PostgreSQL database
```

### Step 7: Test the API
Open your browser or use curl:
```
http://localhost:3001/api/v1/auth/register
```

## Configuration

### Database Settings
The server uses these default settings (in `server.js`):
- Host: `localhost`
- Port: `5432`
- Database: `flow_space`
- User: `postgres`
- Password: `postgres`

**To change these**, edit `backend/server.js` lines 50-56, or create a `.env` file.

### Server Port
- Default: `3001`
- To change: Set `PORT` environment variable or edit `server.js` line 10

## Troubleshooting

### Database Connection Error
1. Ensure PostgreSQL is running
2. Check database `flow_space` exists
3. Verify credentials in `server.js`

### Port Already in Use
```powershell
# Find what's using port 3001
netstat -ano | findstr :3001

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### Missing Dependencies
```powershell
cd backend
npm install
```

## Running in Background (Windows Service)
To run as a Windows service:
```powershell
.\install-windows-service.bat
```

Or use PM2:
```powershell
npm install -g pm2
pm2 start server.js --name flow-space-backend
pm2 save
pm2 startup
```

