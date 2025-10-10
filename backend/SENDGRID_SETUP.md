# SendGrid Email Service Setup Guide

## 🚀 **Quick Setup (5 minutes)**

### **Step 1: Create SendGrid Account**
1. Go to [https://sendgrid.com](https://sendgrid.com)
2. Click "Start for Free"
3. Sign up with your email address
4. Verify your email address

### **Step 2: Get API Key**
1. After login, go to **Settings** → **API Keys**
2. Click **"Create API Key"**
3. Choose **"Restricted Access"**
4. Give it a name: "Flow-Space Backend"
5. Under **Mail Send**, enable **"Full Access"**
6. Click **"Create & View"**
7. **Copy the API key** (starts with `SG.`)

### **Step 3: Configure Your Backend**
1. Create a file called `.env` in the backend folder
2. Add your SendGrid API key:

```env
SENDGRID_API_KEY=SG.your-actual-api-key-here
FROM_EMAIL=noreply@flownet.works
FROM_NAME=Flownet Workspaces
```

### **Step 4: Restart Your Server**
```bash
pm2 restart flow-space-backend
```

## ✅ **Benefits of SendGrid**

- **✅ 100 emails/day FREE** (perfect for development)
- **✅ High deliverability** (emails reach inbox, not spam)
- **✅ Professional sender** (noreply@flownet.works)
- **✅ No Gmail security issues**
- **✅ Detailed analytics** (track email delivery)
- **✅ Fallback to Gmail** (if SendGrid fails)

## 🔧 **Alternative: Use Gmail Only (Quick Fix)**

If you prefer to stick with Gmail for now:

1. **Fix Gmail Security Warning:**
   - Go to your Gmail account
   - Click "Add recovery info" in the warning banner
   - Add a recovery phone number and email
   - Complete Google's security checkup

2. **Update server.js:**
   ```javascript
   const EmailService = require('./emailService'); // Use original Gmail service
   ```

## 📧 **Testing Email Delivery**

After setup, test with:
```bash
node test-email-service.js
```

## 🆘 **Troubleshooting**

- **API Key Issues**: Make sure it starts with `SG.`
- **Domain Issues**: Use a custom domain for `FROM_EMAIL` (optional)
- **Rate Limits**: Free tier allows 100 emails/day
- **Spam Issues**: SendGrid has much better deliverability than Gmail

## 💰 **Pricing**

- **Free Tier**: 100 emails/day forever
- **Paid Plans**: Start at $15/month for 40,000 emails
- **Perfect for**: Development and small production apps
