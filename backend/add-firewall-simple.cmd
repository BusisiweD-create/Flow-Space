@echo off
:: Simple PostgreSQL Firewall Rule Script
:: This will request admin privileges automatically

NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo Running with administrator privileges...
    echo.
    echo Adding PostgreSQL firewall rule...
    powershell -Command "New-NetFirewallRule -DisplayName 'PostgreSQL Server' -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow -Profile Domain,Private"
    echo.
    echo Done! Press any key to close...
    pause >nul
) ELSE (
    echo.
    echo This script requires administrator privileges.
    echo Requesting elevation...
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
)

