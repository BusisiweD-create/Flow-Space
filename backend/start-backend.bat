@echo off
cls
echo ========================================
echo    Flow-Space Backend Server
echo ========================================
echo.
echo Starting server on port 8000...
set PORT=8000
echo.

REM Change to backend directory
cd /d "%~dp0"

REM Start the Node.js server
node server.js

pause
