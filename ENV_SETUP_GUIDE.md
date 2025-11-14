# Environment Variables Setup Guide

## You DO have a database! 🎉

Your project is configured to use **PostgreSQL** database. I can see from your backend configuration that you have:

- ✅ PostgreSQL database setup
- ✅ Database schema files
- ✅ Backend server with database connection
- ✅ Database migration scripts

## What you need: A `.env` file

Your backend server (`server-fixed.js`) is already configured to load environment variables using `require('dotenv').config()`, but you need to create a `.env` file to store your database credentials and other settings.

## Step 1: Create your `.env` file

Create a new file called `.env` in your project root directory with the following content:

```env
# Flow-Space Environment Configuration

# ===========================================
# DATABASE CONFIGURATION
# ===========================================
# PostgreSQL Database Settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flow_space
DB_USER=postgres
DB_PASSWORD=your_actual_postgres_password

# ===========================================
# SERVER CONFIGURATION
# ===========================================
PORT=3000
NODE_ENV=development
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=24h

# ===========================================
# EMAIL CONFIGURATION
# ===========================================
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# ===========================================
# API CONFIGURATION
# ===========================================
API_BASE_URL=http://localhost:3000/api
API_VERSION=v1
```

## Step 2: Update the values

Replace the placeholder values with your actual credentials:

### Database Settings
- `DB_PASSWORD`: Your PostgreSQL password
- `DB_USER`: Usually `postgres` (default)
- `DB_NAME`: `flow_space` (as configured in your server)

### Email Settings
- `SMTP_USER`: Your Gmail address
- `SMTP_PASS`: Your Gmail app password (not your regular password)

### Security
- `JWT_SECRET`: A long, random string for JWT token signing

## Step 3: Set up your PostgreSQL database

1. **Install PostgreSQL** (if not already installed)
2. **Create the database**:
   ```sql
   CREATE DATABASE flow_space;
   ```
3. **Run the schema setup**:
   ```bash
   # Navigate to your project directory
   cd backend
   
   # Run the database setup
   npm run setup
   ```

## Step 4: Test your setup

1. **Start your backend server**:
   ```bash
   cd backend
   npm start
   ```

2. **Check for successful database connection** - you should see:
   ```
   ✅ Connected to PostgreSQL database
   ```

## Your Database Schema

Your project includes comprehensive database schemas:

- **Core Tables**: users, projects, sprints, deliverables
- **Sign-off System**: sign_off_reports, client_reviews
- **Notifications**: notifications, activity_logs
- **File Management**: repository_files, deliverable_evidence

## Database Files Available

- `database_schema_complete.sql` - Complete schema
- `database_migrations.sql` - Incremental migrations

## Next Steps

1. Create the `.env` file with your credentials
2. Set up PostgreSQL database
3. Run the database schema
4. Start your backend server
5. Test the connection

## Troubleshooting

If you get database connection errors:
1. Check if PostgreSQL is running
2. Verify your database credentials in `.env`
3. Ensure the `flow_space` database exists
4. Check if the database user has proper permissions

Your project is well-structured with a complete database setup - you just need to configure the environment variables!
