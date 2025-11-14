# Authentication Testing Guide

This guide will help you test the authentication flow to ensure login issues are resolved.

## Prerequisites

1. **Node.js** installed (version 16 or higher)
2. **PostgreSQL** database running
3. **Flutter** development environment set up

## Backend Testing

### 1. Start the Backend Server

```bash
# Option 1: Use the batch script (Windows)
start-backend.bat

# Option 2: Manual start
cd backend
npm install
cd backend\node-backend && npm start
```

The server should start on `http://localhost:3001`

### 2. Test Backend Endpoints

```bash
# Test server health
curl http://localhost:3001/api/health

# Test database connection
curl http://localhost:3001/api/test-db

# Test registration
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "firstName": "Test",
    "lastName": "User",
    "company": "Test Company",
    "role": "teamMember"
  }'

# Test login
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```

### 3. Run Automated Backend Tests

```bash
# Install axios if not already installed
npm install axios

# Run the test script
node test-auth-flow.js
```

## Frontend Testing

### 1. Start Flutter App

```bash
# In the project root directory
flutter run
```

### 2. Test Login Flow

1. Open the app
2. Navigate to the login screen
3. Try logging in with:
   - **Valid credentials**: `test@example.com` / `testpassword123`
   - **Invalid credentials**: Any other email/password combination
4. Verify error messages are displayed appropriately
5. Verify successful login redirects to dashboard

### 3. Test Registration Flow

1. Navigate to the registration screen
2. Fill in the registration form with valid data
3. Submit the form
4. Verify success message and navigation
5. Try registering with an existing email to test error handling

### 4. Run Flutter Tests

```bash
# Run the authentication integration tests
flutter test test_auth_integration.dart
```

## Expected Results

### ✅ Successful Authentication Flow

1. **Backend Server**: Starts without errors on port 3001
2. **Database Connection**: Health check returns success
3. **Registration**: Returns success with user data and token
4. **Login**: Returns success with user data and token
5. **Frontend**: Login/register forms work without errors
6. **Navigation**: Successful auth redirects to dashboard

### ❌ Common Issues and Solutions

1. **"Database connection failed"**
   - Ensure PostgreSQL is running
   - Check database credentials in `backend/node-backend/src/config/database.js`
   - Verify database exists: `flow_space`

2. **"Network error" in Flutter**
   - Ensure backend server is running
   - Check if Flutter app can reach `localhost:3001`
   - Try using `10.0.2.2:3001` for Android emulator

3. **"Invalid credentials" always**
   - Check if user exists in database
   - Verify password hashing is working
   - Check backend logs for errors

4. **"Token not found" errors**
   - Verify JWT_SECRET is set in backend
   - Check token expiration settings
   - Ensure proper Authorization header format

## Debugging Tips

### Backend Debugging

```bash
# Check backend logs
cd backend
cd backend\node-backend && npm start

# Look for these log messages:
# ✅ Connected to PostgreSQL database
# ✅ User registered: email@example.com
# ✅ User logged in: email@example.com
```

### Frontend Debugging

```bash
# Run Flutter with verbose logging
flutter run --verbose

# Check for these debug messages:
# ✅ User signed in: Name (email)
# ✅ Loaded user: Name (email)
```

### Database Debugging

```sql
-- Connect to PostgreSQL and check users table
SELECT * FROM users WHERE email = 'test@example.com';

-- Check if user is active
SELECT email, is_active FROM users WHERE email = 'test@example.com';
```

## Test Data

For testing purposes, create test accounts in your development environment with appropriate roles and permissions.

## Troubleshooting

If you encounter issues:

1. **Check server logs** for error messages
2. **Verify database connection** with the test endpoint
3. **Test API endpoints** individually with curl/Postman
4. **Check Flutter console** for network errors
5. **Verify token format** in API responses

## Success Criteria

The authentication system is working correctly when:

- [ ] Backend server starts without errors
- [ ] Database connection test passes
- [ ] User registration works and returns token
- [ ] User login works and returns token
- [ ] Flutter app can login with valid credentials
- [ ] Flutter app shows appropriate error messages for invalid credentials
- [ ] Successful login redirects to dashboard
- [ ] User session persists across app restarts
