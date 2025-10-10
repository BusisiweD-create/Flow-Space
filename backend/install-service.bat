@echo off
echo Installing Flow-Space Backend as Windows Service...
echo.

REM Install PM2 as Windows service
pm2 install pm2-windows-service
pm2-service-install

REM Start the application
pm2 start ecosystem.config.js

REM Save PM2 configuration
pm2 save

echo.
echo ✅ Flow-Space Backend installed as Windows Service!
echo 🔄 Server will start automatically on Windows startup
echo 📊 Use 'pm2 status' to check server status
echo 🛑 Use 'pm2 stop flow-space-backend' to stop server
echo.
pause
