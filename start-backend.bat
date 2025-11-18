@echo off
echo ========================================
echo    Flow-Space Backend Server Startup
echo ========================================
echo.

cd /d "%~dp0\backend"

echo Starting server on http://localhost:3001...
echo.
echo Press Ctrl+C to stop the server
echo.

node server.js

echo.
echo Server stopped.
pause