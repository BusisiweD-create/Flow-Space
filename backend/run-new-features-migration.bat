@echo off
echo ========================================
echo Running New Features Migration
echo ========================================
echo.

cd /d "%~dp0"
node migrations/create_new_features_tables.js

echo.
echo Migration complete!
pause

