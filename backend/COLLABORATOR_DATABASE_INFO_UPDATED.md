# 🤝 Database Connection Info for Collaborators

## **Database Connection Details**

Your collaborators can connect to the shared database using these details:

### **Connection Information:**
- **Host:** `192.168.180.64` ⚠️ **Updated IP Address!**
- **Port:** `5432`
- **Database:** `flow_space`
- **Username:** `flowspace_user`
- **Password:** `FlowSpace2024!`

---

## **Setup Instructions for Collaborators**

### **Step 1: Verify Network Connection**
Make sure you're on the same network and can reach the host:
```bash
# Test connectivity
ping 192.168.180.64

# Test if port 5432 is accessible (PowerShell)
Test-NetConnection -ComputerName 192.168.180.64 -Port 5432
```

### **Step 2: Update Database Configuration**
Edit `backend/database-config.js` and set:
```javascript
const ENVIRONMENT = process.env.NODE_ENV || 'shared';
```

### **Step 3: Set Environment Variable**
Create/edit `.env` file in the `backend` directory:
```env
NODE_ENV=shared
```

### **Step 4: Test Connection**
```bash
# Test from collaborator's computer
psql -h 192.168.180.64 -U flowspace_user -d flow_space
# Password: FlowSpace2024!
```

If psql works, try the test script:
```bash
cd backend
node test-database.js
```

### **Step 5: Start the Application**
```bash
# Start backend
cd backend
node server.js

# Start Flutter app (in new terminal)
cd ..
flutter run
```

---

## **Quick Connection Test**

```bash
# From collaborator's computer
psql -h 192.168.180.64 -p 5432 -U flowspace_user -d flow_space

# Or if psql is not installed, use the Node.js test:
cd backend
node test-database.js
```

---

## **What Host Needs to Do**

### **1. Add Firewall Rule** (REQUIRED)
Run **PowerShell as Administrator**:
```powershell
New-NetFirewallRule -DisplayName "PostgreSQL Server" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow -Profile Domain,Private
```

Or use the automated script:
```powershell
# Right-click backend/add-firewall-rule.ps1 → Run with PowerShell
```

### **2. Verify PostgreSQL Config**
Your PostgreSQL is already configured! ✅
- `listen_addresses = '*'` (listening on all interfaces)
- Port 5432 is open

### **3. Keep Computer Online**
Keep your computer running with PostgreSQL service active when collaborators need to connect.

---

## **Important Notes**

### ✅ **Ready:**
- ✅ PostgreSQL is running
- ✅ Port 5432 is listening on all interfaces
- ✅ IP address: 192.168.180.64

### ⚠️ **Required:**
- ⚠️ Add Windows Firewall rule (see above)
- ⚠️ Keep PostgreSQL service running
- ⚠️ Both computers must be on same network

### 🔒 **Security:**
- 🔒 This setup is for development only
- 🔒 Don't use on public networks
- 🔒 Change password for production
- 🔒 Use VPN for remote access

---

## **Troubleshooting**

### **Connection Refused**
```bash
# On host computer (yours)
node backend/verify-external-access.js

# Should show all checks passed
```

**Solutions:**
1. ✅ PostgreSQL running? Check services
2. ✅ Firewall rule added? Run add-firewall-rule.ps1
3. ✅ Same network? Check IP address with `ipconfig`

### **Authentication Failed**
**Solution:** Verify password is: `FlowSpace2024!`

### **Database Not Found**
**Solution:** On host computer, verify database exists:
```bash
psql -U postgres -l
# Should show flow_space in the list
```

### **Can't Reach Host**
```bash
# From collaborator's computer
ping 192.168.180.64
```

**Solutions:**
1. Check network connection
2. Verify IP address hasn't changed: `ipconfig`
3. Check host computer is on and not sleeping
4. Disable any VPN on either computer

---

## **Your Network Details**

**Host Computer (You):**
- IP Address: `192.168.180.64`
- PostgreSQL Port: `5432`
- PostgreSQL Status: ✅ Running

**Collaborators:**
- Must be on same network (192.168.x.x range)
- Need PostgreSQL client tools or Node.js
- Use provided connection details above

---

## **Verification Commands**

### **For Host (You):**
```bash
# Check everything is ready
cd backend
node verify-external-access.js

# Should show all green checkmarks ✅
```

### **For Collaborators:**
```bash
# Test connection
Test-NetConnection -ComputerName 192.168.180.64 -Port 5432

# Connect to database
psql -h 192.168.180.64 -U flowspace_user -d flow_space

# Run application test
cd backend
node test-database.js
```

---

## **Share This File**

Send this file to your collaborators:
- `backend/COLLABORATOR_DATABASE_INFO_UPDATED.md`

Or share via:
- Email
- Slack/Teams
- GitHub (if private repo)
- USB drive

---

**🎉 Once firewall rule is added, share this info with your team!**

**Updated:** November 17, 2025
**Status:** Ready (pending firewall rule)
**Host IP:** 192.168.180.64

