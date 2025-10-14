@echo off
echo Installing Flow-Space Backend as Windows Service...

REM Create a simple service wrapper
echo Creating service wrapper...

REM Install as Windows Service using NSSM (Non-Sucking Service Manager)
REM Download NSSM from https://nssm.cc/download
REM Then run: nssm install FlowSpaceBackend

echo.
echo To install as Windows Service:
echo 1. Download NSSM from https://nssm.cc/download
echo 2. Extract nssm.exe to C:\nssm\
echo 3. Run: C:\nssm\win64\nssm.exe install FlowSpaceBackend
echo 4. Set Path: %CD%\server-fixed.js
echo 5. Set Startup Directory: %CD%
echo 6. Start service: C:\nssm\win64\nssm.exe start FlowSpaceBackend

echo.
echo Alternative: Use Task Scheduler for auto-start
echo 1. Open Task Scheduler
echo 2. Create Basic Task
echo 3. Name: Flow-Space Backend
echo 4. Trigger: At startup
echo 5. Action: Start a program
echo 6. Program: node
echo 7. Arguments: %CD%\server-fixed.js
echo 8. Start in: %CD%

pause