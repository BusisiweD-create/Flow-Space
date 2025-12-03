# 👥 Collaborator Quick Setup Guide

## 🎯 **Goal**
Connect to the shared database instead of running your own PostgreSQL server.

---

## ⚡ **Quick Setup (5 Minutes)**

### **Step 1: Run the Setup Script** (Easiest!)

1. Navigate to `backend` folder
2. Double-click `setup-shared-db.bat`
3. Follow the prompts
4. Done! ✅

### **Step 2: Start Working**

```bash
# Terminal 1 - Backend Server
cd backend
node server.js

# Terminal 2 - Flutter App
flutter run
```

---

## 📋 **Manual Setup (If Script Doesn't Work)**

### **1. Update Database Config**

Edit `backend/database-config.js`:

```javascript
// Line ~3-5, change this:
const ENVIRONMENT = process.env.NODE_ENV || 'development';

// To this:
const ENVIRONMENT = process.env.NODE_ENV || 'shared';
```

### **2. Create .env File**

In `backend` folder, create `.env`:

```env
NODE_ENV=shared
```

### **3. Test Connection**

```bash
cd backend
node test-database.js
```

✅ Should show: "Database test completed successfully!"

---

## 🌐 **Connection Details**

**You're connecting to:**
- **Host**: 192.168.180.64
- **Port**: 5432
- **Database**: flow_space
- **Username**: flowspace_user
- **Password**: FlowSpace2024!

*(These are already configured in database-config.js)*

---

## ✅ **Verify You're Connected**

After setup, check:

```bash
cd backend
node test-database.js
```

**Should show:**
```
✅ Connected to database successfully
👥 Users: 5
📁 Projects: 4
🎉 Database test completed successfully!
```

---

## 🔧 **Troubleshooting**

### **Can't Connect?**

**1. Test network connection:**
```bash
ping 192.168.180.64
```
✅ Should get replies

**2. Test database port:**
```powershell
Test-NetConnection -ComputerName 192.168.180.64 -Port 5432
```
✅ TcpTestSucceeded should be True

**3. Common Issues:**

| Problem | Solution |
|---------|----------|
| Connection refused | Check same network, host computer on |
| Timeout | Check firewall, VPN interference |
| Auth failed | Verify password: `FlowSpace2024!` |
| Database not found | Host needs to verify PostgreSQL running |

---

## 🆘 **Still Having Issues?**

Contact the database host (computer with IP 192.168.180.64) and verify:
- ✅ PostgreSQL service is running
- ✅ Port 5432 firewall rule is active
- ✅ Both computers on same network
- ✅ Host computer is not sleeping

---

## 📊 **What You're Sharing**

When connected to shared database, you share:
- ✅ Users and authentication
- ✅ Projects and deliverables
- ✅ Sign-off reports
- ✅ Digital signatures
- ✅ All application data

**Benefits:**
- No need to run PostgreSQL locally
- Everyone sees same data in real-time
- True collaboration!

---

## 🚀 **After Setup**

You can now:
1. Login with existing users
2. Create and submit reports
3. Sign reports with e-signatures
4. View shared projects
5. Collaborate in real-time!

---

## 📞 **Need Help?**

1. Run `setup-shared-db.bat` first
2. Check troubleshooting section above
3. Contact database host
4. See `backend/COLLABORATOR_DATABASE_INFO_UPDATED.md` for detailed info

---

**Happy Collaborating! 🎉**

*Last Updated: November 2025*

