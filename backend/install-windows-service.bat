@echo off
echo ========================================
echo  Installing Flow-Space as Windows Service
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator - Good!
) else (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Installing PM2 as Windows Service...
pm2 install pm2-windows-service

echo Starting Flow-Space Backend...
pm2 start ecosystem.config.js

echo Saving PM2 configuration...
pm2 save

echo Setting up auto-start...
pm2-startup install

echo.
echo ========================================
echo  ✅ Installation Complete!
echo ========================================
echo.
echo Your Flow-Space backend will now:
echo - Start automatically when Windows boots
echo - Restart automatically if it crashes
echo - Run in the background
echo.
echo Management commands:
echo - pm2 status          (check server status)
echo - pm2 logs            (view server logs)
echo - pm2 restart         (restart server)
echo - pm2 stop            (stop server)
echo.
pause
