# 🤝 Flow-Space Database Sharing Guide

## **Current Setup Status**

✅ **Database Config Ready:** `database-config.js` supports local, shared, and cloud modes  
✅ **Shared User Setup:** `setup-shared-db.sql` creates `flowspace_user` for collaborators  
✅ **Database:** `flowspace_dev`  
✅ **Your Credentials:** `postgres` / `Refiloe@2024`  
✅ **Shared Credentials:** `flowspace_user` / `FlowSpace2024!`

---

## **🚀 Quick Start: Enable Sharing NOW**

### **Step 1: Create Shared User** (One-time setup)

Open **pgAdmin** and run this:

```sql
-- Connect to flowspace_dev
\c flowspace_dev

-- Create shared user
CREATE USER flowspace_user WITH PASSWORD 'FlowSpace2024!';
GRANT ALL PRIVILEGES ON DATABASE flowspace_dev TO flowspace_user;
GRANT ALL ON SCHEMA public TO flowspace_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO flowspace_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO flowspace_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO flowspace_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO flowspace_user;
```

### **Step 2: Find Your IP Address**

**Windows PowerShell:**
```powershell
ipconfig
# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100
```

**Copy your IP address** (looks like `192.168.x.x` or `10.x.x.x`)

### **Step 3: Update Shared Config**

Edit `backend/database-config.js` line 17:

```javascript
shared: {
  user: 'flowspace_user',
  host: 'YOUR_IP_ADDRESS_HERE',  // ⬅️ Put your IP address here!
  database: 'flowspace_dev',
  password: 'FlowSpace2024!',
  port: 5432,
},
```

### **Step 4: Enable PostgreSQL Remote Connections**

#### **4.1 Find PostgreSQL Config Files**

```powershell
# Find your PostgreSQL data directory
psql -U postgres -c "SHOW config_file"
# Example output: C:\Program Files\PostgreSQL\14\data\postgresql.conf
```

#### **4.2 Edit `postgresql.conf`**

Open as Administrator and change:
```conf
# BEFORE:
#listen_addresses = 'localhost'

# AFTER:
listen_addresses = '*'
```

#### **4.3 Edit `pg_hba.conf`** (same directory)

Add this line at the end:
```conf
# Allow flowspace_user from local network
host    flowspace_dev    flowspace_user    192.168.0.0/16    md5
host    flowspace_dev    flowspace_user    10.0.0.0/8        md5
```

#### **4.4 Restart PostgreSQL**

**Windows Services:**
1. Press `Win + R`
2. Type `services.msc`
3. Find `postgresql-x64-14` (or your version)
4. Right-click → **Restart**

**Or via PowerShell (as Administrator):**
```powershell
Restart-Service postgresql-x64-14
```

### **Step 5: Open Windows Firewall**

**Windows Defender Firewall:**
1. Search for "Windows Defender Firewall"
2. Click **Advanced Settings**
3. Click **Inbound Rules** → **New Rule...**
4. Rule Type: **Port**
5. TCP, Specific port: **5432**
6. Allow the connection
7. All profiles (Domain, Private, Public)
8. Name: "PostgreSQL for Flow-Space"

**Or via PowerShell (as Administrator):**
```powershell
New-NetFirewallRule -DisplayName "PostgreSQL" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow
```

---

## **👥 For Collaborators**

### **What You Need from Project Owner:**

- **Host:** Their IP address (e.g., `192.168.1.100`)
- **Port:** `5432`
- **Database:** `flowspace_dev`
- **Username:** `flowspace_user`
- **Password:** `FlowSpace2024!`

### **Setup Steps:**

1. **Clone the Flow-Space repository**
   ```bash
   git clone <repo-url>
   cd Flow-Space/backend
   ```

2. **Update `database-config.js`** (line 17):
   ```javascript
   shared: {
     user: 'flowspace_user',
     host: 'OWNER_IP_ADDRESS',  // ⬅️ IP from project owner
     database: 'flowspace_dev',
     password: 'FlowSpace2024!',
     port: 5432,
   },
   ```

3. **Set environment to use shared database:**
   
   **Windows PowerShell:**
   ```powershell
   $env:NODE_ENV="shared"
   npm install
   node server.js
   ```
   
   **Mac/Linux:**
   ```bash
   export NODE_ENV=shared
   npm install
   node server.js
   ```

4. **Test the connection:**
   ```bash
   psql -h OWNER_IP_ADDRESS -U flowspace_user -d flowspace_dev
   # Password: FlowSpace2024!
   ```

---

## **🧪 Testing Connection**

### **From Your Machine:**
```bash
# Should work (localhost)
psql -h localhost -U flowspace_user -d flowspace_dev
```

### **From Collaborator's Machine:**
```bash
# Replace with your actual IP
psql -h 192.168.1.100 -U flowspace_user -d flowspace_dev
```

---

## **🔄 Switching Between Modes**

### **Use Local Mode** (default):
```powershell
# No environment variable needed
node server.js
# Uses: postgres@localhost/flowspace_dev
```

### **Use Shared Mode** (for collaborators):
```powershell
$env:NODE_ENV="shared"
node server.js
# Uses: flowspace_user@your-ip/flowspace_dev
```

### **Use Cloud Mode** (future):
```powershell
$env:NODE_ENV="cloud"
node server.js
# Uses cloud database from config
```

---

## **🔒 Security Best Practices**

1. **Change the default password** in `database-config.js` and `setup-shared-db.sql`
2. **Use VPN** for remote collaborators outside your network
3. **Whitelist specific IP addresses** in `pg_hba.conf` instead of entire subnets
4. **Enable SSL** for production:
   ```javascript
   ssl: {
     rejectUnauthorized: false,
     ca: fs.readFileSync('/path/to/ca-certificate.crt').toString(),
   }
   ```
5. **Regular backups:**
   ```bash
   pg_dump -U postgres flowspace_dev > backup_$(date +%Y%m%d).sql
   ```

---

## **☁️ Moving to Cloud Database (Future)**

When ready for production, migrate to a cloud provider:

### **Option 1: Supabase** (Recommended)
1. Sign up at [supabase.com](https://supabase.com)
2. Create new project → Get connection string
3. Update `database-config.js` cloud section
4. Export your data:
   ```bash
   pg_dump -U postgres flowspace_dev > export.sql
   ```
5. Import to Supabase via their dashboard

### **Option 2: Neon** (Serverless)
- Free 10GB storage
- Auto-scaling
- Instant database branches

### **Option 3: Railway/Render**
- Free PostgreSQL hosting
- Auto-deploy from GitHub
- Automatic backups

---

## **🆘 Troubleshooting**

### **"Connection refused"**
- ✅ Check PostgreSQL is running
- ✅ Verify `listen_addresses = '*'` in `postgresql.conf`
- ✅ Restart PostgreSQL service

### **"No pg_hba.conf entry"**
- ✅ Add entry for your network in `pg_hba.conf`
- ✅ Restart PostgreSQL after changes

### **"Role does not exist"**
- ✅ Run `setup-shared-db.sql` to create `flowspace_user`

### **"Firewall blocking"**
- ✅ Open port 5432 in Windows Firewall
- ✅ Check antivirus/security software

### **"Can connect locally but not remotely"**
- ✅ Verify both computers on same network
- ✅ Check router firewall settings
- ✅ Ping the host IP address first

---

## **📞 Support**

If collaborators can't connect:
1. Share this guide with them
2. Verify they're using `NODE_ENV=shared`
3. Test connection with `psql` first before running app
4. Check both computers can ping each other

---

**You're all set! 🎉** Your database is ready for collaboration!

