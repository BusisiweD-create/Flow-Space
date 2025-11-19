@echo off
echo.
echo ========================================
echo   SETUP REPORTS TABLES
echo ========================================
echo.

node setup-reports-tables.js

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Success! Press any key to exit...
) else (
    echo.
    echo Failed! Check the error above.
    echo Press any key to exit...
)

pause > nul

