# 🤝 Database Connection Info for Collaborators

## **Database Connection Details**

Your collaborators can connect to the shared database using these details:

### **Connection Information:**
- **Host:** `172.19.48.1`
- **Port:** `5432`
- **Database:** `flow_space`
- **Username:** `flowspace_user`
- **Password:** `FlowSpace2024!`

## **Setup Instructions for Collaborators**

### **Step 1: Update Database Configuration**
Edit `backend/database-config.js` and set:
```javascript
const ENVIRONMENT = process.env.NODE_ENV || 'shared';
```

### **Step 2: Set Environment Variable**
Create a `.env` file in the `backend` directory:
```env
NODE_ENV=shared
```

### **Step 3: Test Connection**
```bash
# Test from collaborator's computer
psql -h 172.19.48.1 -U flowspace_user -d flow_space
# Password: FlowSpace2024!
```

### **Step 4: Start the Application**
```bash
# Start backend
cd backend
node server.js

# Start Flutter app
cd ..
flutter run
```

## **Important Notes**

1. **Network Access Required:** Collaborators must be on the same network as you
2. **Firewall:** Make sure port 5432 is open in your firewall
3. **PostgreSQL Config:** Ensure PostgreSQL accepts external connections
4. **Security:** This setup is for development only

## **Troubleshooting**

- **Connection Refused:** Check if PostgreSQL is running and firewall settings
- **Authentication Failed:** Verify username/password
- **Database Not Found:** Ensure database exists and user has access

## **Your IP Address:**
`172.19.48.1`

---
**Share this information with your collaborators! 🚀**
