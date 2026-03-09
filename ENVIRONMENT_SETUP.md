# Environment Configuration Guide

This document explains how to configure and switch between different environments in the Flow-Space application.

## Available Environments

- **PROD**: Production environment (`https://flow-space.onrender.com/api/v1`)
- **SIT**: System Integration Testing (`https://flow-space-sit.onrender.com/api/v1`)
- **DEV**: Development environment (`http://localhost:3001/api/v1`)
- **LOCAL**: Local development (`http://localhost:3001/api/v1`)

## Current Environment

The application is currently configured for: **SIT**

## Environment Files

### Frontend Configuration
- **File**: `frontend/lib/config/environment.dart`
- **Purpose**: Defines API endpoints and environment-specific settings
- **Current Setting**: `SIT`

### Backend Configuration
- **File**: `backend/node-backend/.env.{environment}`
- **Purpose**: Database connections, JWT secrets, and server settings
- **Current File**: `.env.sit`

## Switching Environments

### Method 1: Using the Switch Script (Recommended)

```bash
# Switch to SIT environment
node scripts/switch-env.js sit

# Switch to Production
node scripts/switch-env.js prod

# Switch to Development
node scripts/switch-env.js dev
```

### Method 2: Manual Configuration

#### Frontend
Edit `frontend/lib/config/environment.dart`:
```dart
static const String _currentEnvironment = 'SIT'; // Change this value
```

#### Backend
1. Create/edit `backend/node-backend/.env.{environment}`
2. Set `NODE_ENV={environment}` when starting the server:
   ```bash
   NODE_ENV=sit npm start
   ```

## Environment Variables

### Backend Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_ENV` | Environment name | `sit`, `prod`, `dev` |
| `PORT` | Server port | `3001` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `flow_space_sit` |
| `DB_USER` | Database username | `postgres` |
| `DB_PASSWORD` | Database password | `your_password` |
| `JWT_SECRET` | JWT signing secret | `your_secret_key` |
| `CORS_ORIGIN` | Allowed CORS origins | `http://localhost:3000` |

### Frontend Environment Configuration

The frontend automatically uses the correct API URL based on the environment:

```dart
static const Map<String, String> _environmentUrls = {
  'PROD': 'https://flow-space.onrender.com/api/v1',
  'SIT': 'https://flow-space-sit.onrender.com/api/v1',
  'DEV': 'http://localhost:3001/api/v1',
  'LOCAL': 'http://localhost:3001/api/v1',
};
```

## Starting the Application

### Backend (SIT Environment)
```bash
cd backend/node-backend
NODE_ENV=sit npm start
```

### Frontend
The frontend automatically picks up the environment configuration. Just restart the app after changing environments.

## Verification

### Check Frontend Environment
When the app starts, you'll see console logs:
```
Current Environment: SIT
API Base URL: https://flow-space-sit.onrender.com/api/v1
Is Production: false
Is SIT: true
Is Development: false
```

### Check Backend Environment
When the backend starts, you'll see:
```
==================================================
🌍 Environment: SIT
==================================================
Environment variables loaded from: .env.sit
NODE_ENV: sit
PORT: 3001
==================================================
```

## Database Setup

Each environment should use its own database:

- **Production**: `flow_space_prod`
- **SIT**: `flow_space_sit`
- **Development**: `flow_space_dev`
- **Local**: `flow_space_local`

Make sure to create the appropriate database and run migrations for each environment.

## Security Notes

- Never commit `.env` files with real secrets to version control
- Use different JWT secrets for each environment
- Ensure database credentials are environment-specific
- Production should use SSL certificates and secure connections

## Troubleshooting

### Issues with Environment Switching
1. Ensure the backend `.env.{environment}` file exists
2. Check that `NODE_ENV` is set correctly when starting the backend
3. Restart both frontend and backend after switching
4. Clear browser cache/cookies if needed

### API Connection Issues
1. Verify the API URL is correct for the environment
2. Check if the backend server is running on the correct port
3. Ensure CORS is configured properly for the environment
4. Check network connectivity to the API endpoint

### Database Issues
1. Verify database exists for the environment
2. Check database credentials in the `.env` file
3. Run migrations if needed: `npm run migrate`
