# 🚀 Quick Start - Backend Server

## Option 1: Start on Port 8000 (Recommended)

Run this in a **new terminal window**:

```powershell
cd backend
.\start-server-8000.ps1
```

The server will start on `http://localhost:8000`

## Option 2: Use Default Port 3001

If port 8000 doesn't work, you can change the Flutter app to use port 3001:

1. Update `lib/services/api_client.dart` line 12:
   ```dart
   static const String _baseUrl = 'http://localhost:3001/api';
   ```

2. Update `lib/config/environment.dart` line 10:
   ```dart
   static const String apiBaseUrl = "http://localhost:3001/api/v1";
   ```

3. Then start backend normally:
   ```powershell
   cd backend
   .\start-server.ps1
   ```

## Verify Server is Running

Open browser: `http://localhost:8000/health` (or `:3001` if using Option 2)

You should see a health check response.

## Troubleshooting

- **Database connection error**: Make sure PostgreSQL is running
- **Port already in use**: Kill the process using that port
- **Module not found**: Run `npm install` in the backend folder

