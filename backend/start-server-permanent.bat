@echo off
title Flow-Space Backend Server
echo ========================================
echo    Flow-Space Backend Server
echo ========================================
echo.
echo Starting server in shared database mode...
echo Server will run on: http://localhost:3000
echo API endpoint: http://localhost:3000/api
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

cd /d "%~dp0"
set NODE_ENV=shared
node server.js

echo.
echo Server stopped. Press any key to restart...
pause > nul
goto :eof
