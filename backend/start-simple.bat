@echo off
echo ========================================
echo Flow-Space Backend Server
echo ========================================
echo Database: flow_space @ localhost
echo Environment: local
echo Port: 8000
echo ========================================
echo.

cd /d %~dp0
set NODE_ENV=local

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    echo.
)

echo Starting server on port 8000...
set PORT=8000
echo.

node server.js

if errorlevel 1 (
    echo.
    echo Server stopped with an error.
    echo Check the error message above.
    pause
)


