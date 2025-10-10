#!/bin/bash

# Flow-Space Backend Setup Script
echo "🚀 Setting up Flow-Space Backend..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ Node.js and npm are installed"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "⚠️  PostgreSQL is not installed."
    echo "💡 Please install PostgreSQL:"
    echo "   - Windows: Download from https://www.postgresql.org/download/windows/"
    echo "   - macOS: brew install postgresql"
    echo "   - Ubuntu: sudo apt-get install postgresql postgresql-contrib"
    echo ""
    echo "🔄 After installing PostgreSQL, run this script again."
    exit 1
fi

echo "✅ PostgreSQL is installed"

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo "⚠️  PostgreSQL is not running."
    echo "💡 Please start PostgreSQL:"
    echo "   - Windows: Start PostgreSQL service"
    echo "   - macOS: brew services start postgresql"
    echo "   - Ubuntu: sudo systemctl start postgresql"
    echo ""
    echo "🔄 After starting PostgreSQL, run this script again."
    exit 1
fi

echo "✅ PostgreSQL is running"

# Create database and tables
echo "🗄️  Setting up database..."
node setup-database.js

if [ $? -eq 0 ]; then
    echo "✅ Database setup completed successfully"
else
    echo "❌ Database setup failed"
    exit 1
fi

# Test database connection
echo "🧪 Testing database connection..."
node test-database.js

if [ $? -eq 0 ]; then
    echo "✅ Database test passed"
else
    echo "❌ Database test failed"
    exit 1
fi

echo ""
echo "🎉 Flow-Space Backend setup completed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Start the server: node server-updated.js"
echo "   2. Test the API endpoints"
echo "   3. Run the Flutter app to test the full system"
echo ""
echo "🔗 Useful commands:"
echo "   - Start server: node server-updated.js"
echo "   - Test database: node test-database.js"
echo "   - Setup database: node setup-database.js"
echo ""
echo "📊 API Endpoints:"
echo "   - Health: http://localhost:3000/health"
echo "   - Register: POST http://localhost:3000/api/v1/auth/register"
echo "   - Login: POST http://localhost:3000/api/v1/auth/login"
echo "   - Current User: GET http://localhost:3000/api/v1/auth/me"
echo "   - Users (Admin): GET http://localhost:3000/api/v1/users"
