@echo off
echo ========================================
echo  Creating Windows Startup Task
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

echo Creating Windows Task for Flow-Space Backend...
schtasks /create /tn "Flow-Space Backend" /tr "cmd /c cd /d \"%~dp0\" && set NODE_ENV=shared && node server.js" /sc onstart /ru "SYSTEM" /f

echo.
echo ========================================
echo  ✅ Task Created Successfully!
echo ========================================
echo.
echo Your Flow-Space backend will now:
echo - Start automatically when Windows boots
echo - Run in the background
echo.
echo To manage the task:
echo - Task Scheduler > Task Scheduler Library > Flow-Space Backend
echo - Or run: schtasks /query /tn "Flow-Space Backend"
echo.
pause
