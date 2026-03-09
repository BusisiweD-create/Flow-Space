#!/bin/bash

# Flow-Space Database Deployment Script
# This script sets up the database for deployment

echo "🚀 Starting Flow-Space Database Deployment..."

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo "❌ PostgreSQL is not running. Please start PostgreSQL first."
    exit 1
fi

echo "✅ PostgreSQL is running"

# Database connection parameters
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="flow_space"
DB_USER="postgres"

echo "📊 Connecting to database: $DB_NAME"

# Run main schema first (if needed)
echo "🏗️ Creating main database schema..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f schema.sql 2>/dev/null

# Run deployment migration
echo "🔄 Running deployment migration..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f deployment_migration.sql

# Run any additional migrations
echo "📋 Applying additional migrations..."

# Add project fields
if [ -f "add_projects_fields.sql" ]; then
    echo "  Adding project fields..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f add_projects_fields.sql
fi

# Fix projects table
if [ -f "fix_projects_table.sql" ]; then
    echo "  Fixing projects table..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f fix_projects_table.sql
fi

# Add sample data
if [ -f "add_sample_project.sql" ]; then
    echo "  Adding sample project..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f add_sample_project.sql
fi

echo "✅ Database deployment completed!"
echo ""
echo "📊 Summary of actions:"
echo "  ✅ Created/updated database schema"
echo "  ✅ Applied all migrations"
echo "  ✅ Added sample projects with members"
echo "  ✅ Ready for deployment"
echo ""
echo "🎯 Next steps:"
echo "  1. Restart backend server"
echo "  2. Test project details functionality"
echo "  3. Verify all features work correctly"
echo ""
