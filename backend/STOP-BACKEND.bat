@echo off
cls
echo ========================================
echo    Stopping Flow-Space Backend Server
echo ========================================
echo.

REM Kill all Node.js processes
taskkill /F /IM node.exe /T >nul 2>&1

echo Backend server stopped!
echo.
pause

