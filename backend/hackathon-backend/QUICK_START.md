# Quick Start Guide - PostgreSQL Setup

## 🚀 3-Minute Setup

### 1. Configure Environment
Edit `.env` file with:
```bash
DATABASE_URL=postgresql://flowspace_user:FlowSpace2024!@172.19.48.1:5432/flow_space
NODE_ENV=shared
```

### 2. Test Connection
```bash
# Quick test
python -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://flowspace_user:FlowSpace2024!@172.19.48.1:5432/flow_space')
    print('✅ Connected!')
    conn.close()
except Exception as e:
    print(f'❌ Error: {e}')
"
```

### 3. Run Server
```bash
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8001
```

## 📋 Connection Details
- **Host**: 172.19.48.1
- **Port**: 5432  
- **Database**: flow_space
- **Username**: flowspace_user
- **Password**: FlowSpace2024!

## ✅ Verification
```bash
# Health check
curl http://127.0.0.1:8001/health

# Test auth (after starting server)
curl -X POST http://127.0.0.1:8001/api/v1/auth/login \
  -d "grant_type=password&username=demo@example.com&password=password123"
```

## 🆘 Troubleshooting
- **Connection issues**: Check firewall/network to 172.19.48.1:5432
- **Auth failed**: Verify password is `FlowSpace2024!`
- **Server not starting**: Check Python dependencies with `pip install -r requirements.txt`

## 📚 Full Documentation
See `POSTGRES_SETUP.md` for complete instructions.