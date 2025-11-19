@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "start-server-robust.ps1"
pause

