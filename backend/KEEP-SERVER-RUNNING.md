# 🚀 Keep Server Running Guide

## Quick Start

### Option 1: Double-click to start (Easiest)
1. Double-click `start-server.bat` in the `backend` folder
2. A PowerShell window will open - **KEEP IT OPEN**
3. The server will start automatically
4. If it crashes, it will try to restart

### Option 2: PowerShell script
1. Open PowerShell in the `backend` folder
2. Run: `.\start-server.ps1`
3. **KEEP THE WINDOW OPEN**

## ✅ Verify Server is Running

1. Open a browser
2. Go to: `http://localhost:3001/api/health`
3. You should see: `{"status":"OK","message":"Flow-Space API is running"}`

## 🔧 Troubleshooting

### Server won't start?
- Check if port 3001 is already in use
- Make sure PostgreSQL is running
- Check the PowerShell window for error messages

### Connection Refused errors?
1. **Hard refresh your browser**: `Ctrl + Shift + R`
2. Check if the server PowerShell window is still open
3. Verify server is running: Visit `http://localhost:3001/api/health`

### Server keeps crashing?
- Check the PowerShell window for error messages
- Verify database connection in `database-config.js`
- Make sure all dependencies are installed: `npm install`

## 📝 Notes

- **DO NOT CLOSE** the PowerShell window where the server is running
- The server must stay running for the app to work
- If you close it, restart using `start-server.bat`

