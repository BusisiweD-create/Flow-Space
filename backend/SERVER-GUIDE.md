# Flow-Space Backend Server Guide

## 🚀 Server Startup Options

The Flow-Space backend server can be started in several ways depending on your needs:

### 1. **Development Mode (Auto-restart)**
```bash
# Using npm script
npm run dev

# Or directly with nodemon
nodemon server-fixed.js
```
**Best for:** Development and testing
**Features:** Auto-restart on file changes, detailed logging

### 2. **Production Mode (PM2)**
```bash
# Start with PM2
pm2 start ecosystem.config.js

# Check status
pm2 status

# View logs
pm2 logs flow-space-backend

# Stop server
pm2 stop flow-space-backend

# Restart server
pm2 restart flow-space-backend
```
**Best for:** Production deployment
**Features:** Process management, auto-restart, logging, monitoring

### 3. **Simple Mode (Manual)**
```bash
# Start server
npm start

# Or directly
node server-fixed.js
```
**Best for:** Quick testing
**Features:** Simple startup, manual restart needed

### 4. **Windows Batch Script**
```bash
# Double-click or run
start-server.bat
```
**Best for:** Windows users who want simple startup
**Features:** Auto-restart, Windows-friendly

### 5. **Unix/Linux Shell Script**
```bash
# Make executable and run
chmod +x start-server.sh
./start-server.sh
```
**Best for:** Unix/Linux users who want simple startup
**Features:** Auto-restart, Unix-friendly

## 📊 Server Status

### Health Check
```bash
curl http://localhost:3000/health
```

### Test Database Connection
```bash
curl http://localhost:3000/api/v1/test
```

### Check Server Logs
```bash
# PM2 logs
pm2 logs flow-space-backend

# Direct logs (if using batch/shell scripts)
# Check console output
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the backend directory:
```env
NODE_ENV=production
PORT=3000
JWT_SECRET=your-secure-secret-key
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your-password
DB_NAME=flow_space
```

### Database Configuration
Update `database-config.js` with your PostgreSQL settings:
```javascript
const config = {
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'your-password',
  port: 5432,
};
```

## 🧪 Testing the Server

### 1. Health Check
```bash
curl http://localhost:3000/health
```
Expected response:
```json
{
  "status": "OK",
  "message": "Flow-Space Backend Server",
  "database": "Connected",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "version": "2.0.0"
}
```

### 2. Test Database
```bash
curl http://localhost:3000/api/v1/test
```
Expected response:
```json
{
  "success": true,
  "message": "Database connection working",
  "data": {
    "userCount": "1",
    "databaseConnected": true
  }
}
```

### 3. Register User
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "role": "teamMember"
  }'
```

### 4. Login User
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## 🛠️ Troubleshooting

### Server Won't Start
1. **Check if port 3000 is in use:**
   ```bash
   netstat -an | findstr :3000
   ```

2. **Check database connection:**
   ```bash
   node test-database.js
   ```

3. **Check dependencies:**
   ```bash
   npm install
   ```

### Database Connection Issues
1. **Verify PostgreSQL is running:**
   ```bash
   psql --version
   ```

2. **Test database setup:**
   ```bash
   node simple-database-setup.js
   ```

3. **Check database configuration:**
   - Verify `database-config.js` settings
   - Ensure PostgreSQL is accessible
   - Check database exists: `flow_space`

### Server Keeps Stopping
1. **Check logs for errors:**
   ```bash
   pm2 logs flow-space-backend
   ```

2. **Restart with PM2:**
   ```bash
   pm2 restart flow-space-backend
   ```

3. **Use auto-restart script:**
   ```bash
   # Windows
   start-server.bat
   
   # Unix/Linux
   ./start-server.sh
   ```

## 📈 Monitoring

### PM2 Monitoring
```bash
# View all processes
pm2 list

# Monitor in real-time
pm2 monit

# View detailed info
pm2 show flow-space-backend
```

### Log Files
- **PM2 logs:** `pm2 logs flow-space-backend`
- **File logs:** `./logs/` directory
- **Console output:** Direct terminal output

## 🔄 Auto-Start on Boot

### Windows (Task Scheduler)
1. Open Task Scheduler
2. Create Basic Task
3. Set trigger: "When the computer starts"
4. Set action: "Start a program"
5. Program: `cmd.exe`
6. Arguments: `/c cd "C:\path\to\backend" && start-server.bat`

### Linux (systemd)
Create `/etc/systemd/system/flow-space.service`:
```ini
[Unit]
Description=Flow-Space Backend Server
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/backend
ExecStart=/usr/bin/node server-fixed.js
Restart=always

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl enable flow-space
sudo systemctl start flow-space
```

## 🎯 Recommended Setup

### For Development
```bash
npm run dev
```

### For Production
```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

### For Simple Testing
```bash
# Windows
start-server.bat

# Unix/Linux
./start-server.sh
```

---

**Flow-Space Backend Server** - Role-based project management system with PostgreSQL and Node.js
