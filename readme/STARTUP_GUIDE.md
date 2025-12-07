# Flow-Space Application Startup Guide

## 🚀 Quick Start

### 1. Start Backend Server

**Option A: Using PowerShell (Recommended)**
```powershell
.\start-backend.ps1
```

**Option B: Using Batch File**
```cmd
start-backend.bat
```

**Option C: Manual Start**
```powershell
cd backend
node server.js
```

### 2. Start Flutter Frontend

```bash
flutter run -d chrome
```

## ✅ Verification

### Backend Server Status
- **URL:** http://localhost:3001
- **Health Check:** http://localhost:3001/api/test-db
- **Status:** Should show "Database connection successful"

### Login Credentials
- **Email:** bdhlamini883@gmail.com
- **Password:** password123

## 🔧 Troubleshooting

### Server Not Starting
1. Make sure you're in the correct directory (`backend` folder)
2. Check if port 3001 is already in use
3. Verify Node.js is installed: `node --version`

### Login Issues
1. Ensure backend server is running on port 3001
2. Check browser console for connection errors
3. Verify database connection in backend logs

### Flutter Issues
1. Run `flutter clean` and `flutter pub get`
2. Check for any linting errors: `flutter analyze`
3. Ensure all dependencies are installed

## 📁 Project Structure

```
Flow-Space/
├── backend/           # Node.js backend server
│   ├── server.js      # Main server file
│   └── start-server.bat
├── lib/               # Flutter frontend
│   ├── main.dart      # App entry point
│   ├── screens/       # UI screens
│   └── services/      # API services
└── start-backend.ps1  # Server startup script
```

## 🎯 Features Working

✅ **Authentication**
- User login with real credentials
- Session management
- Token-based authentication

✅ **Sprint Management**
- Create and manage sprints
- Sprint status updates (planning, in_progress, completed, cancelled)
- Real-time status changes

✅ **Project Management**
- Create projects with name, key, and description
- Project listing and management

✅ **Ticket Management**
- Create tickets in sprints
- Drag and drop ticket status changes
- Real-time persistence

✅ **Navigation**
- Sprint console to sprint board navigation
- Proper routing with GoRouter

## 🚨 Important Notes

1. **Always start the backend server first** before running the Flutter app
2. **Keep the backend server running** while using the application
3. **Use the provided startup scripts** for consistent server startup
4. **Check the terminal** for any error messages if something doesn't work

## 📞 Support

If you encounter any issues:
1. Check the backend server logs
2. Verify database connection
3. Ensure all dependencies are installed
4. Check browser console for frontend errors
