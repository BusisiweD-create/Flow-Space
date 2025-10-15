require('dotenv').config();

console.log('🔍 Checking environment variables in node-backend:');
console.log('NODE_ENV:', process.env.NODE_ENV || 'not set');
console.log('SMTP_HOST:', process.env.SMTP_HOST || 'not set');
console.log('SMTP_PORT:', process.env.SMTP_PORT || 'not set');
console.log('SMTP_USER:', process.env.SMTP_USER || 'not set');
console.log('SMTP_PASS:', process.env.SMTP_PASS ? '*** (set)' : 'not set');

// Check if .env file exists
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
    console.log('📁 .env file exists');
    console.log('📄 .env file content:');
    console.log(fs.readFileSync(envPath, 'utf8'));
} else {
    console.log('❌ .env file does not exist in node-backend directory');
    console.log('💡 Copying .env from parent directory...');
    
    const parentEnvPath = path.join(__dirname, '..', '.env');
    if (fs.existsSync(parentEnvPath)) {
        fs.copyFileSync(parentEnvPath, envPath);
        console.log('✅ Copied .env file from parent directory');
    } else {
        console.log('❌ Parent .env file also not found');
    }
}