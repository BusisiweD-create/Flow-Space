# 🚀 Run Server with `node server.js`

## Quick Start

```bash
cd backend
node server.js
```

## If Server Stops

### 1. Missing Dependencies (MODULE_NOT_FOUND)
```bash
npm install
```

### 2. Database Connection Error
Make sure:
- PostgreSQL is running
- Database `flow_space` exists
- Check connection settings in `server.js` or `.env` file

### 3. Port Already in Use
```powershell
# Find what's using port 8000
netstat -ano | findstr :8000

# Kill the process (replace PID)
taskkill /PID <PID> /F
```

## Environment Variables (Optional)

Create a `.env` file in the `backend` folder:
```
PORT=8000
NODE_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flow_space
DB_USER=postgres
DB_PASSWORD=postgres
```

## Success Message

When server starts successfully, you'll see:
```
✅ Database connection established successfully
🚀 Server running on port 8000
```

## Keep Server Running

The server will keep running until you press `Ctrl+C` to stop it.

