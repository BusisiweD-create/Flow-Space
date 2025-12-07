# OpenAI Setup Guide (Free Tier)

## Getting Your Free API Key

OpenAI offers **$5 free credit** to new users, which is enough for hundreds of readiness analyses!

### Step 1: Create OpenAI Account
1. Go to https://platform.openai.com/signup
2. Sign up with your email
3. Verify your email address

### Step 2: Get API Key
1. Go to https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy the key (you'll only see it once!)
4. Save it securely

### Step 3: Add to Environment
Add to `backend/.env` file:
```
OPENAI_API_KEY=sk-your-key-here
```

### Step 4: Restart Server
```bash
cd backend
node server.js
```

You should see: `✅ OpenAI initialized (GPT-3.5-turbo)`

---

## Cost Information

**GPT-3.5-turbo Pricing:**
- Input: $0.50 per 1M tokens
- Output: $1.50 per 1M tokens
- **Average cost per analysis: ~$0.001-0.002** (very cheap!)

**Free Credit:**
- $5 free credit for new users
- Enough for **2,500-5,000 analyses**

**After Free Credit:**
- Pay-as-you-go
- Very affordable for production use

---

## Troubleshooting

### "OPENAI_API_KEY not set"
- Check that you added the key to `backend/.env`
- Restart the server after adding the key

### "OpenAI package not installed"
```bash
cd backend
npm install openai
```

### API Errors
- Check your API key is valid
- Verify you have credits available
- System will automatically fallback to rule-based analysis

---

## Testing

1. Create a deliverable in the app
2. Check backend console for: `✅ AI analysis completed using GPT-3.5-turbo`
3. You should see AI-powered insights in the readiness gate widget

---

## Model Used

We're using **GPT-3.5-turbo** which is:
- ✅ Fast and efficient
- ✅ Very affordable
- ✅ Excellent for structured analysis
- ✅ Perfect for this use case

GPT-4 is more powerful but costs ~10x more. GPT-3.5-turbo is the sweet spot for cost and quality!

