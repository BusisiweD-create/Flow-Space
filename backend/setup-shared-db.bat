@echo off
echo ============================================
echo Flow-Space Shared Database Setup
echo ============================================
echo.
echo This script will configure your environment
echo to connect to the shared database.
echo.
echo Host: 192.168.180.64
echo Port: 5432
echo Database: flow_space
echo.
pause
echo.

:: Check if .env exists
if exist .env (
    echo .env file found. Backing up...
    copy .env .env.backup
    echo Old .env saved as .env.backup
    echo.
)

:: Create .env file
echo Creating .env file...
echo NODE_ENV=shared > .env
echo ✅ .env file created with NODE_ENV=shared
echo.

:: Test connection
echo Testing database connection...
echo.
node test-database.js

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo ✅ SUCCESS! Connected to shared database
    echo ============================================
    echo.
    echo You can now run:
    echo   1. Terminal 1: node server.js
    echo   2. Terminal 2: flutter run
    echo.
) else (
    echo.
    echo ============================================
    echo ❌ Connection Failed
    echo ============================================
    echo.
    echo Troubleshooting:
    echo   1. Verify you're on the same network
    echo   2. Ping the host: ping 192.168.180.64
    echo   3. Test port: Test-NetConnection -ComputerName 192.168.180.64 -Port 5432
    echo   4. Contact the database host
    echo.
)

echo.
pause

