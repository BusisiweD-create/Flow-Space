# 🌍 ENVIRONMENT VARIABLES SETUP GUIDE

## 📋 **REQUIRED ENVIRONMENT VARIABLES**

### **SendGrid Configuration**
```bash
# SendGrid API Key (get from SendGrid Dashboard → Settings → API Keys)
SENDGRID_API_KEY=SG.xxxxxxxxxxxx.yyyyyyyyyyyyyyyyyyyyyyyy

# Verified Sender Email (must match verified sender in SendGrid)
FROM_EMAIL=dhlamininaomi1@gmail.com

# Sender Display Name
FROM_NAME=Flownet Workspaces

# Reply-to Email (optional)
EMAIL_REPLY_TO=dhlamininaomi1@gmail.com
```

### **Database Configuration**
```bash
# PostgreSQL Database URL
DATABASE_URL=postgresql://username:password@localhost:5432/database_name

# Alternative Database Config
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flow_space
DB_USER=your_username
DB_PASSWORD=your_password
```

### **JWT Configuration**
```bash
# JWT Secret Key (generate a strong secret)
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# JWT Expiration Time
JWT_EXPIRES_IN=24h
```

### **SMTP Fallback Configuration**
```bash
# SMTP Configuration (backup email service)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM_EMAIL=your-email@gmail.com
```

---

## 🔧 **SETUP INSTRUCTIONS**

### **Step 1: Get SendGrid API Key**
1. **Login to SendGrid Dashboard**: https://app.sendgrid.com
2. **Go to Settings**: Click on "API Keys" in the left menu
3. **Create API Key**: 
   - Click "Create API Key"
   - Give it a name (e.g., "Flow-Space Production")
   - Select "Full Access" or "Mail Send" permissions
   - Copy the generated key immediately
4. **Verify Key Format**: Should start with "SG."

### **Step 2: Verify Sender Email**
1. **Sender Authentication**: Go to Settings → Sender Authentication
2. **Single Sender**: Verify `dhlamininaomi1@gmail.com` is listed
3. **Complete Verification**: 
   - Click "Verify" next to the email
   - Check email inbox for verification link
   - Complete verification process
4. **Domain Authentication** (if using custom domain):
   - Set up SPF records
   - Set up DKIM authentication
   - Set up DMARC records

### **Step 3: Set Environment Variables**

#### **For Local Development:**
Create `.env` file in backend directory:
```bash
cd backend
touch .env
```

Add variables to `.env` file:
```bash
SENDGRID_API_KEY=SG.your_actual_api_key_here
FROM_EMAIL=dhlamininaomi1@gmail.com
FROM_NAME=Flownet Workspaces
DATABASE_URL=postgresql://localhost:5432/flow_space
JWT_SECRET=your-super-secret-jwt-key
```

#### **For Production (Render):**
1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Select Your Service**: Click on the Flow-Space backend service
3. **Environment Tab**: Go to "Environment" tab
4. **Add Variables**: Add each required variable
5. **Restart Service**: Click "Manual Deploy" to apply changes

### **Step 4: Verify Setup**
```bash
# Test configuration
cd backend
node test-sendgrid-config.cjs
```

Expected output:
```
🔧 SendGrid Configuration Test
================================

📋 Step 1: Checking Environment Variables
-------------------------------------------
SENDGRID_API_KEY: ✅ Set (SG.xxxxxx...)
FROM_EMAIL: ✅ Set (dhlamininaomi1@gmail.com)
FROM_NAME: ✅ Set (Flownet Workspaces)
API Key Format: ✅ Valid (SG.xxxx...)

🔍 Step 2: Testing SendGrid Service
----------------------------------------
✅ SendGrid service initialized successfully

📧 Step 3: Testing Connection & Sender
--------------------------------------
✅ Connection test result: PASSED

🎉 SendGrid Configuration is Ready!
=====================================
✅ API Key: Valid format
✅ Sender: Verified
✅ Connection: Successful
```

---

## 🚨 **COMMON ISSUES & SOLUTIONS**

### **Issue: API Key Format Invalid**
**Error**: `API Key Format: ❌ Invalid`
**Cause**: Key doesn't start with "SG."
**Solution**:
1. Generate new API key from SendGrid dashboard
2. Ensure key has "Mail Send" permissions
3. Copy key exactly as shown (no extra spaces)

### **Issue: 403 Forbidden Errors**
**Error**: `🚫 SendGrid Error: Sender not authorized`
**Cause**: Sender email not verified in SendGrid
**Solution**:
1. Go to SendGrid Settings → Sender Authentication
2. Complete email verification process
3. Wait for verification to complete (may take 24 hours)

### **Issue: Environment Variables Not Loading**
**Error**: `FROM_EMAIL: ❌ Not set`
**Cause**: .env file not found or variables not set
**Solution**:
1. Create `.env` file in backend directory
2. Add variables with correct format
3. Restart application

### **Issue: Module Import Errors**
**Error**: `require is not defined in ES module scope`
**Cause**: Mixed ES modules and CommonJS
**Solution**:
1. Use `.cjs` extension for CommonJS scripts
2. Or use ES module imports consistently

---

## 📞 **SUPPORT CONTACT**

### **SendGrid Support**
- **Dashboard**: https://app.sendgrid.com
- **Documentation**: https://docs.sendgrid.com
- **Status Page**: https://status.sendgrid.com

### **Environment Issues**
- **Render Dashboard**: https://dashboard.render.com
- **Environment Variables**: Check service environment tab
- **Logs**: Check service logs in Render dashboard

---

*This guide ensures all required environment variables are correctly configured for SendGrid email functionality.*
