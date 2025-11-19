@echo off
echo ============================================
echo PostgreSQL Firewall Rule Setup
echo ============================================
echo.
echo Adding firewall rule for PostgreSQL port 5432...
echo.

powershell -Command "New-NetFirewallRule -DisplayName 'PostgreSQL Server' -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow -Profile Domain,Private"

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo SUCCESS! Firewall rule added.
    echo ============================================
    echo.
    echo PostgreSQL is now accessible from your network!
    echo.
    echo Your IP address:
    ipconfig | findstr "IPv4"
    echo.
    echo Share this IP with collaborators.
    echo.
) else (
    echo.
    echo ============================================
    echo ERROR: Failed to add firewall rule
    echo ============================================
    echo.
    echo Please make sure you:
    echo 1. Right-click this file
    echo 2. Select "Run as administrator"
    echo.
)

echo.
echo Press any key to close...
pause > nul

