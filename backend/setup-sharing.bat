@echo off
echo Setting up PostgreSQL for sharing with collaborators...
echo.

echo Step 1: Finding your IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set IP=%%a
    goto :found
)
:found
echo Your IP address is: %IP%
echo.

echo Step 2: Please run these commands in PostgreSQL:
echo.
echo 1. Connect to PostgreSQL as superuser:
echo    psql -U postgres
echo.
echo 2. Run the setup script:
echo    \i setup-shared-db.sql
echo.
echo 3. Update your database-config.js with:
echo    - Host: %IP%
echo    - Username: flowspace_user
echo    - Password: FlowSpace2024!
echo.
echo 4. Share these details with your collaborators:
echo    - Host: %IP%
echo    - Port: 5432
echo    - Database: flow_space
echo    - Username: flowspace_user
echo    - Password: FlowSpace2024!
echo.
echo 5. Make sure PostgreSQL accepts connections:
echo    - Edit postgresql.conf: listen_addresses = '*'
echo    - Edit pg_hba.conf: host all all 0.0.0.0/0 md5
echo    - Restart PostgreSQL service
echo.
pause
