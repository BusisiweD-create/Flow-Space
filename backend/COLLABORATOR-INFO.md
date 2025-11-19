# 🤝 Database Connection Info for Collaborators

## **Database Connection Details**

Your collaborators can connect to the shared database using these details:

### **Connection Information:**
- **Host:** `172.19.48.1`
- **Port:** `5432`
- **Database:** `flow_space`
- **Username:** `flowspace_user`
- **Password:** `FlowSpace2024!`

---

## **Setup Instructions for Collaborators**

### **Step 1: Clone the Repository**
```bash
git clone <your-repo-url>
cd Flow-Space
```

### **Step 2: Update Database Configuration**
Edit `backend/database-config.js` and ensure the `shared` config matches:

```javascript
shared: {
  user: 'flowspace_user',
  host: '172.19.48.1',
  database: 'flow_space',
  password: 'FlowSpace2024!',
  port: 5432,
},
```

### **Step 3: Set Environment Variable**

**Windows PowerShell:**
```powershell
$env:NODE_ENV="shared"
```

**Mac/Linux:**
```bash
export NODE_ENV=shared
```

**Or create `.env` file in backend directory:**
```env
NODE_ENV=shared
```

### **Step 4: Install Dependencies**
```bash
# Backend
cd backend
npm install

# Frontend
cd ..
flutter pub get
```

### **Step 5: Test Database Connection**
```bash
# Test connection (if psql is installed)
psql -h 172.19.48.1 -U flowspace_user -d flow_space
# Password: FlowSpace2024!
```

### **Step 6: Start the Application**

**Terminal 1 - Backend:**
```bash
cd backend
$env:NODE_ENV="shared"  # Windows
node server.js
```

**Terminal 2 - Frontend:**
```bash
flutter run -d chrome
```

---

## **Important Notes**

1. **Network Access Required:** Collaborators must be on the same network as the database host (172.19.48.1)
2. **Firewall:** Make sure port 5432 is open in the host's firewall
3. **PostgreSQL Config:** Host machine has PostgreSQL configured to accept external connections
4. **Security:** This setup is for development/local network only
5. **Database Owner:** You (host) can use `NODE_ENV=local` to connect as postgres user

---

## **Database Modes**

### **For Database Owner (You):**
```powershell
# Use local mode (full admin access)
# No environment variable needed, or:
$env:NODE_ENV="local"
node server.js
# Connects as: postgres@172.19.48.1/flow_space
```

### **For Collaborators:**
```powershell
# Use shared mode (collaborator access)
$env:NODE_ENV="shared"
node server.js
# Connects as: flowspace_user@172.19.48.1/flow_space
```

---

## **Troubleshooting**

### **Connection Refused**
✅ Check if PostgreSQL is running on host machine  
✅ Verify firewall allows port 5432  
✅ Ping the host IP: `ping 172.19.48.1`  
✅ Try `telnet 172.19.48.1 5432` to test port access  

### **Authentication Failed**
✅ Verify username: `flowspace_user`  
✅ Verify password: `FlowSpace2024!`  
✅ Check `pg_hba.conf` on host has entry for your IP  

### **Database Not Found**
✅ Ensure database name is `flow_space` (with underscore)  
✅ Verify user has access: `GRANT ALL ON DATABASE flow_space TO flowspace_user;`  

### **Tables Not Found**
✅ Host needs to run database setup scripts  
✅ Check with host if schema is initialized  

### **"Module not found" errors**
✅ Run `npm install` in backend directory  
✅ Run `flutter pub get` in root directory  

---

## **Your Network Setup**

- **Database Host IP:** 172.19.48.1
- **Network Type:** Local Network (192.168.x.x or 172.x.x.x)
- **Access Level:** Same network required

**For Remote Access (outside local network):**
- Host needs to set up port forwarding on router
- Or use VPN solution
- Or migrate to cloud database (Supabase, Neon, etc.)

---

## **Quick Test Commands**

```bash
# Test network connectivity
ping 172.19.48.1

# Test PostgreSQL port
telnet 172.19.48.1 5432
# Or on Windows PowerShell:
Test-NetConnection -ComputerName 172.19.48.1 -Port 5432

# Test database connection
psql -h 172.19.48.1 -U flowspace_user -d flow_space

# Start backend in shared mode
cd backend
$env:NODE_ENV="shared"
node server.js

# Check environment
echo $env:NODE_ENV
```

---

## **Support**

If you have issues connecting:
1. Contact the database host (owner)
2. Verify you're on the same network
3. Share error messages for troubleshooting
4. Check both machines can ping each other

---

**Share this file with your collaborators! 🚀**

*Last Updated: Database setup for IP 172.19.48.1*

