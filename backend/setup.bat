@echo off
REM Flow-Space Backend Setup Script for Windows

echo 🚀 Setting up Flow-Space Backend...

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    echo 💡 Download from: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js is installed

REM Check if npm is installed
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ npm is not installed. Please install npm first.
    pause
    exit /b 1
)

echo ✅ npm is installed

REM Install dependencies
echo 📦 Installing dependencies...
npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed successfully

REM Check if PostgreSQL is installed
psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  PostgreSQL is not installed.
    echo 💡 Please install PostgreSQL:
    echo    - Download from: https://www.postgresql.org/download/windows/
    echo    - Make sure to add PostgreSQL to your PATH
    echo.
    echo 🔄 After installing PostgreSQL, run this script again.
    pause
    exit /b 1
)

echo ✅ PostgreSQL is installed

REM Check if PostgreSQL is running
pg_isready >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  PostgreSQL is not running.
    echo 💡 Please start PostgreSQL:
    echo    - Open Services (services.msc)
    echo    - Find "postgresql" service
    echo    - Start the service
    echo.
    echo 🔄 After starting PostgreSQL, run this script again.
    pause
    exit /b 1
)

echo ✅ PostgreSQL is running

REM Create database and tables
echo 🗄️  Setting up database...
node setup-database.js
if %errorlevel% neq 0 (
    echo ❌ Database setup failed
    pause
    exit /b 1
)

echo ✅ Database setup completed successfully

REM Test database connection
echo 🧪 Testing database connection...
node test-database.js
if %errorlevel% neq 0 (
    echo ❌ Database test failed
    pause
    exit /b 1
)

echo ✅ Database test passed

echo.
echo 🎉 Flow-Space Backend setup completed successfully!
echo.
echo 📝 Next steps:
echo    1. Start the server: node server-updated.js
echo    2. Test the API endpoints
echo    3. Run the Flutter app to test the full system
echo.
echo 🔗 Useful commands:
echo    - Start server: node server-updated.js
echo    - Test database: node test-database.js
echo    - Setup database: node setup-database.js
echo.
echo 📊 API Endpoints:
echo    - Health: http://localhost:3000/health
echo    - Register: POST http://localhost:3000/api/v1/auth/register
echo    - Login: POST http://localhost:3000/api/v1/auth/login
echo    - Current User: GET http://localhost:3000/api/v1/auth/me
echo    - Users (Admin): GET http://localhost:3000/api/v1/users
echo.
pause
