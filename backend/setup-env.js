const fs = require('fs');
const path = require('path');

// Create .env file with secure defaults
const envContent = `# Database Configuration
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=flow_space
DB_PORT=5432

# SMTP Email Configuration - REPLACE WITH YOUR ACTUAL CREDENTIALS
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# JWT Secret - REPLACE WITH A SECURE RANDOM STRING
JWT_SECRET=your_secure_jwt_secret_key_here

# Server Configuration
PORT=3000
NODE_ENV=development`;

const envPath = path.join(__dirname, '.env');

if (!fs.existsSync(envPath)) {
  fs.writeFileSync(envPath, envContent);
  console.log('✅ Created .env file with secure defaults');
  console.log('⚠️  IMPORTANT: Update the SMTP credentials in backend/.env');
} else {
  console.log('ℹ️  .env file already exists');
}
