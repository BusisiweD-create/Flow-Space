@echo off
REM Flow-Space Backend Server Startup Script
REM This script starts the server and keeps it running

echo 🚀 Starting Flow-Space Backend Server...
echo 📅 Started at: %date% %time%
echo.

REM Change to backend directory
cd /d "%~dp0"

REM Start the server
echo Starting server with auto-restart...
node server-fixed.js

REM If server stops, restart it
echo.
echo ⚠️  Server stopped. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto :start

:start
echo 🔄 Restarting server...
node server-fixed.js
goto :start