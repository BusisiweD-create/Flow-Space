@echo off
echo Starting Flow-Space Backend Server...
echo.
echo Server will run on http://localhost:3001
echo Press Ctrl+C to stop the server
echo.

cd /d "%~dp0"
node server.js

pause