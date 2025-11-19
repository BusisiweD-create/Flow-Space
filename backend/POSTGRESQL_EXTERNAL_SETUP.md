# 🌐 PostgreSQL External Connection Setup Guide

## **Step 1: Edit `postgresql.conf`**

### **Location:**
```
C:\Program Files\PostgreSQL\16\data\postgresql.conf
```

### **What to Change:**

1. **Open the file as Administrator** (right-click Notepad → Run as Administrator)

2. **Find this line** (around line 59):
```conf
#listen_addresses = 'localhost'
```

3. **Change it to:**
```conf
listen_addresses = '*'
```
   - Remove the `#` (uncomment)
   - Change `'localhost'` to `'*'` (listen on all network interfaces)

4. **Optional: Find and uncomment** (around line 63):
```conf
port = 5432
```

5. **Save the file**

---

## **Step 2: Edit `pg_hba.conf` - Allow Network Access**

### **Location:**
```
C:\Program Files\PostgreSQL\16\data\pg_hba.conf
```

### **What to Add:**

1. **Open the file as Administrator**

2. **Scroll to the bottom** of the file

3. **Add these lines** at the end:
```conf
# Allow connections from local network (192.168.x.x or 172.x.x.x)
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Allow flowspace_user from any IP on local network
host    flow_space      flowspace_user  192.168.0.0/16          md5
host    flow_space      flowspace_user  172.16.0.0/12           md5
host    flow_space      flowspace_user  10.0.0.0/8              md5

# Allow postgres user from localhost only (security)
host    all             postgres        127.0.0.1/32            md5
host    all             postgres        ::1/128                 md5
```

**Explanation:**
- `192.168.0.0/16` - Allows all 192.168.x.x addresses
- `172.16.0.0/12` - Allows all 172.16.x.x to 172.31.x.x addresses
- `10.0.0.0/8` - Allows all 10.x.x.x addresses
- `md5` - Requires password authentication

4. **Save the file**

---

## **Step 3: Configure Windows Firewall**

### **Option A: Using PowerShell (Recommended)**

Open **PowerShell as Administrator** and run:

```powershell
# Create firewall rule for PostgreSQL
New-NetFirewallRule -DisplayName "PostgreSQL Server" `
  -Direction Inbound `
  -LocalPort 5432 `
  -Protocol TCP `
  -Action Allow `
  -Profile Domain,Private

# Verify the rule was created
Get-NetFirewallRule -DisplayName "PostgreSQL Server"
```

### **Option B: Using Windows Firewall GUI**

1. Press `Win + R`, type `wf.msc`, press Enter
2. Click **"Inbound Rules"** → **"New Rule..."**
3. Select **"Port"** → Next
4. Select **"TCP"**, enter port **5432** → Next
5. Select **"Allow the connection"** → Next
6. Check **"Domain"** and **"Private"** (uncheck Public for security) → Next
7. Name: **"PostgreSQL Server"** → Finish

---

## **Step 4: Restart PostgreSQL Service**

### **Using Services (GUI):**
1. Press `Win + R`, type `services.msc`, press Enter
2. Find **"postgresql-x64-16"** (or similar)
3. Right-click → **Restart**

### **Using PowerShell:**
```powershell
# Run as Administrator
Restart-Service postgresql-x64-16

# Or find the exact service name first:
Get-Service | Where-Object {$_.DisplayName -like "*PostgreSQL*"}
# Then restart with the correct name
```

### **Using Command Prompt:**
```cmd
:: Run as Administrator
net stop postgresql-x64-16
net start postgresql-x64-16
```

---

## **Step 5: Test the Configuration**

### **Test 1: From Your Computer (Host)**
```bash
# Should work with localhost
psql -h localhost -U flowspace_user -d flow_space

# Should also work with your IP
psql -h 172.19.48.1 -U flowspace_user -d flow_space
```

### **Test 2: From Collaborator's Computer**
```bash
# They should be able to connect
psql -h 172.19.48.1 -U flowspace_user -d flow_space
# Password: FlowSpace2024!
```

### **Test 3: Check if Port is Open**
```powershell
# On your computer (host)
netstat -an | findstr :5432

# Should show:
# TCP    0.0.0.0:5432    0.0.0.0:0    LISTENING
```

### **Test 4: From Collaborator - Check Connection**
```powershell
# On collaborator's computer
Test-NetConnection -ComputerName 172.19.48.1 -Port 5432

# Should show:
# TcpTestSucceeded : True
```

---

## **Step 6: Verify Settings**

Run this on your computer to check the configuration:

```sql
-- Connect to PostgreSQL
psql -U postgres

-- Check listen addresses
SHOW listen_addresses;
-- Should show: *

-- Check port
SHOW port;
-- Should show: 5432

-- Check client connections
SELECT * FROM pg_stat_activity;
```

---

## **Security Best Practices**

### ✅ **DO:**
- ✅ Only allow specific IP ranges (192.168.x.x, 172.x.x.x)
- ✅ Use strong passwords
- ✅ Use `md5` or `scram-sha-256` authentication
- ✅ Limit firewall to Domain/Private networks only
- ✅ Only allow `flowspace_user` from network (not `postgres`)

### ❌ **DON'T:**
- ❌ Don't use `trust` authentication (no password)
- ❌ Don't allow from `0.0.0.0/0` (entire internet)
- ❌ Don't open firewall on Public networks
- ❌ Don't allow `postgres` superuser from network

---

## **Troubleshooting**

### **Problem: Connection Refused**
```
psql: error: connection to server at "172.19.48.1", port 5432 failed:
Connection refused
```

**Solutions:**
1. Check if PostgreSQL is running
2. Verify `listen_addresses = '*'` in postgresql.conf
3. Restart PostgreSQL service
4. Check firewall allows port 5432

---

### **Problem: Password Authentication Failed**
```
psql: error: password authentication failed for user "flowspace_user"
```

**Solutions:**
1. Verify password is correct: `FlowSpace2024!`
2. Check `pg_hba.conf` has entry for the user
3. Restart PostgreSQL after pg_hba.conf changes

---

### **Problem: No Route to Host**
```
psql: error: could not connect to server: No route to host
```

**Solutions:**
1. Verify IP address is correct: `ipconfig`
2. Ensure both computers are on same network
3. Test network connectivity: `ping 172.19.48.1`
4. Check firewall on host computer

---

### **Problem: Timeout**
```
psql: error: could not connect to server: Operation timed out
```

**Solutions:**
1. Check Windows Firewall allows inbound on port 5432
2. Check antivirus/security software
3. Verify router/network allows the connection

---

## **Quick Verification Script**

Save this as `test-external-connection.bat`:

```batch
@echo off
echo Testing PostgreSQL External Connection Setup...
echo.

echo 1. Checking if PostgreSQL is running...
sc query postgresql-x64-16 | findstr "RUNNING"
if %errorlevel% neq 0 (
    echo [FAIL] PostgreSQL service is not running
) else (
    echo [OK] PostgreSQL is running
)
echo.

echo 2. Checking if port 5432 is listening...
netstat -an | findstr ":5432.*LISTENING"
if %errorlevel% neq 0 (
    echo [FAIL] Port 5432 is not listening
) else (
    echo [OK] Port 5432 is listening
)
echo.

echo 3. Checking firewall rule...
netsh advfirewall firewall show rule name="PostgreSQL Server" | findstr "Enabled"
if %errorlevel% neq 0 (
    echo [WARN] Firewall rule may not be enabled
) else (
    echo [OK] Firewall rule is active
)
echo.

echo 4. Your IP address:
ipconfig | findstr "IPv4"
echo.

echo Setup verification complete!
pause
```

Run it to verify your setup!

---

## **Summary Checklist**

- [ ] Edited `postgresql.conf` → `listen_addresses = '*'`
- [ ] Edited `pg_hba.conf` → Added network access rules
- [ ] Opened Windows Firewall → Port 5432 allowed
- [ ] Restarted PostgreSQL service
- [ ] Tested localhost connection works
- [ ] Tested IP connection works
- [ ] Shared IP address with collaborators
- [ ] Collaborators can connect successfully

---

**Once completed, your database will accept external connections!** 🎉

