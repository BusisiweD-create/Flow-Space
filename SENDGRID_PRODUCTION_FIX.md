# SendGrid Production Setup Guide

## 🔧 Step 1: Verify SendGrid Account

1. **Login to SendGrid**: https://app.sendgrid.com
2. **Check API Key**:
   - Go to Settings → API Keys
   - Verify your key has "Mail Send" permissions
   - Ensure key is not expired

## 🔑 Step 2: Create Proper API Key

If you need a new key:

1. **Create API Key**:
   - Click "Create API Key"
   - Select "Restricted Access"
   - Enable "Mail Send" permission
   - Give it a name like "Flow-Space-Production"

2. **Copy the Key**:
   - Copy the full key (starts with `SG.`)
   - Store it securely

## 🌐 Step 3: Verify Sender Identity

1. **Single Sender Verification**:
   - Go to Settings → Sender Authentication
   - Verify your email domain or single sender
   - This is REQUIRED for production

## 🚀 Step 4: Configure Render Environment

Add these EXACT environment variables in Render:

```
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
FROM_NAME=Flow-Space
FROM_EMAIL=noreply@yourdomain.com
EMAIL_REPLY_TO=support@yourdomain.com
```

**Important**:
- Replace `SG.xxxxx...` with your actual API key
- Replace `yourdomain.com` with your verified sender domain
- Make sure there are NO extra spaces or quotes

## 🧪 Step 5: Test SendGrid

After deployment, check logs for:
```
✅ SendGrid initialized successfully
```

If you still see:
```
❌ Failed to send verification email via SendGrid: Unauthorized
```

Then the API key is invalid or lacks permissions.

## 📋 Common Issues:

1. **API Key Format**: Must start with `SG.`
2. **Permissions**: Must have "Mail Send" enabled
3. **Sender Verification**: Domain/email must be verified
4. **Environment Variables**: No spaces, exact names

## 🎯 Quick Test Command:

You can test your API key locally:
```bash
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"personalizations":[{"to":[{"email":"test@example.com"}]}],"from":{"email":"test@example.com"},"subject":"Test","content":[{"type":"text/plain","value":"Test"}]}'
```
