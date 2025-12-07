@echo off
cls
echo ========================================
echo    Flow-Space Backend Server
echo ========================================
echo.
echo Starting server on port 3001...
echo.

REM Change to backend directory
cd /d "%~dp0"

REM Start the Node.js server
node server.js

pause
