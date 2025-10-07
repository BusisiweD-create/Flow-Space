# 🗄️ PostgreSQL Database Sharing Setup

## **Step 1: Configure PostgreSQL for Network Access**

### **1.1 Update PostgreSQL Configuration**

Edit your PostgreSQL configuration file (`postgresql.conf`):
```bash
# Find your postgresql.conf file (usually in PostgreSQL data directory)
# On Windows: C:\Program Files\PostgreSQL\15\data\postgresql.conf
# On Mac: /usr/local/var/postgres/postgresql.conf
# On Linux: /etc/postgresql/15/main/postgresql.conf

# Uncomment and modify these lines:
listen_addresses = '*'          # Allow connections from any IP
port = 5432                     # Default PostgreSQL port
max_connections = 100           # Increase if needed
```

### **1.2 Update pg_hba.conf for Authentication**

Edit your `pg_hba.conf` file (in the same directory):
```bash
# Add this line to allow connections from your network:
# Replace 192.168.1.0/24 with your actual network range
host    all             all             192.168.1.0/24        md5

# Or for any IP (less secure, use only for development):
host    all             all             0.0.0.0/0               md5
```

### **1.3 Restart PostgreSQL Service**

**Windows:**
```cmd
# Open Command Prompt as Administrator
net stop postgresql-x64-15
net start postgresql-x64-15
```

**Mac:**
```bash
brew services restart postgresql
```

**Linux:**
```bash
sudo systemctl restart postgresql
```

## **Step 2: Create Database and User**

### **2.1 Connect to PostgreSQL as Superuser**
```bash
psql -U postgres
```

### **2.2 Create Database and User**
```sql
-- Create database
CREATE DATABASE flow_space;

-- Create user for collaborators
CREATE USER flowspace_user WITH PASSWORD 'your_secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE flow_space TO flowspace_user;

-- Connect to the database
\c flow_space

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO flowspace_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO flowspace_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO flowspace_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO flowspace_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO flowspace_user;
```

## **Step 3: Update Database Configuration**

### **3.1 Update database-config.js**
```javascript
const config = {
  // Your local database (for you)
  local: {
    user: 'postgres',
    host: 'localhost',
    database: 'flow_space',
    password: 'postgres',
    port: 5432,
  },
  
  // Shared database (for collaborators)
  shared: {
    user: 'flowspace_user',
    host: 'YOUR_IP_ADDRESS', // Your computer's IP address
    database: 'flow_space',
    password: 'your_secure_password',
    port: 5432,
  }
};

// Use shared database for collaborators
const ENVIRONMENT = process.env.NODE_ENV || 'shared';
const selectedConfig = config[ENVIRONMENT] || config.shared;

module.exports = selectedConfig;
```

### **3.2 Find Your IP Address**

**Windows:**
```cmd
ipconfig
# Look for "IPv4 Address" under your network adapter
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
# Look for your local network IP (usually 192.168.x.x or 10.x.x.x)
```

## **Step 4: Share with Collaborators**

### **4.1 Give Collaborators These Details:**
- **Host:** Your computer's IP address
- **Port:** 5432
- **Database:** flow_space
- **Username:** flowspace_user
- **Password:** your_secure_password

### **4.2 Collaborators Setup:**
1. Install PostgreSQL client tools
2. Update their `database-config.js` with your details
3. Set `NODE_ENV=shared` in their environment

## **Step 5: Test Connection**

### **5.1 Test from Your Computer:**
```bash
psql -h localhost -U flowspace_user -d flow_space
```

### **5.2 Test from Collaborator's Computer:**
```bash
psql -h YOUR_IP_ADDRESS -U flowspace_user -d flow_space
```

## **Step 6: Security Considerations**

### **6.1 Firewall Settings**
Make sure port 5432 is open in your firewall:
- **Windows:** Windows Defender Firewall
- **Mac:** System Preferences → Security & Privacy → Firewall
- **Linux:** ufw or iptables

### **6.2 Network Security**
- Use strong passwords
- Consider VPN for remote access
- Regularly update PostgreSQL
- Monitor connection logs

## **Step 7: Alternative - Use ngrok for Remote Access**

If you want to share from anywhere (not just local network):

### **7.1 Install ngrok:**
```bash
# Download from https://ngrok.com
# Or install via package manager
```

### **7.2 Expose PostgreSQL:**
```bash
ngrok tcp 5432
# This will give you a public URL like: tcp://0.tcp.ngrok.io:12345
```

### **7.3 Share the ngrok URL:**
- **Host:** 0.tcp.ngrok.io (from ngrok output)
- **Port:** 12345 (from ngrok output)
- **Database:** flow_space
- **Username:** flowspace_user
- **Password:** your_secure_password

## **Troubleshooting**

### **Connection Refused:**
- Check if PostgreSQL is running
- Verify firewall settings
- Check if port 5432 is open

### **Authentication Failed:**
- Verify username/password
- Check pg_hba.conf configuration
- Ensure user has proper privileges

### **Database Not Found:**
- Make sure database exists
- Check if user has access to database
- Verify connection parameters

---

**Your collaborators will be able to connect to your database and work on the same data! 🚀**
