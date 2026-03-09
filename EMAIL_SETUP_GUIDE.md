// Simple Email Service Configuration Guide

## 📧 Email Setup Options

### Option 1: Gmail SMTP (Recommended for Development)

1. **Enable App Password in Gmail:**
   - Go to: https://myaccount.google.com/apppasswords
   - Enable 2-factor authentication if not already enabled
   - Generate an App Password for "Flow-Space"
   - Copy the 16-character password

2. **Add these Environment Variables in Render:**
   ```
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_SECURE=false
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-16-character-app-password
   SMTP_FROM_NAME=Flow-Space
   SMTP_FROM_EMAIL=your-email@gmail.com
   ```

### Option 2: SendGrid (Production)

1. **Get SendGrid API Key:**
   - Sign up at: https://sendgrid.com
   - Generate an API key
   - Verify your sender identity

2. **Add these Environment Variables in Render:**
   ```
   SENDGRID_API_KEY=SG.xxxxx...
   FROM_NAME=Flow-Space
   FROM_EMAIL=noreply@yourdomain.com
   EMAIL_REPLY_TO=support@yourdomain.com
   ```

### Option 3: Disable Email (Quick Fix)

If you want to disable email verification temporarily:

1. **Add this Environment Variable:**
   ```
   DISABLE_EMAIL_VERIFICATION=true
   ```

## 🔧 Quick Test

After setting up environment variables, restart your Render service and try registering again.

## 📋 Current Status

Your app is working perfectly - email is the only optional enhancement.
Users can still register using verification codes shown in logs.
