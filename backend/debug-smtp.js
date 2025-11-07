const nodemailer = require('nodemailer');

console.log('🔍 Debugging SMTP configuration...');
console.log('SMTP_HOST:', process.env.SMTP_HOST);
console.log('SMTP_PORT:', process.env.SMTP_PORT);
console.log('SMTP_USER:', process.env.SMTP_USER);
console.log('SMTP_PASS length:', process.env.SMTP_PASS ? process.env.SMTP_PASS.length : 'undefined');

// Test with different password formats
const passwordsToTest = [
  process.env.SMTP_PASS, // original
  process.env.SMTP_PASS?.replace(/\s+/g, ''), // remove spaces
  'bplcqegzkspgotfk' // without spaces
];

async function testConnection(password) {
  console.log(`\n🧪 Testing with password: "${password}" (length: ${password?.length})`);
  
  try {
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: password
      }
    });
    
    await transporter.verify();
    console.log('✅ SMTP connection successful!');
    return true;
  } catch (error) {
    console.log('❌ SMTP connection failed:', error.message);
    return false;
  }
}

async function main() {
  for (const password of passwordsToTest) {
    if (password) {
      const success = await testConnection(password);
      if (success) {
        console.log('🎉 Found working password format!');
        return;
      }
    }
  }
  
  console.log('\n❌ All password formats failed. Please check:');
  console.log('1. Gmail app password is correct');
  console.log('2. Two-factor authentication is enabled on Gmail');
  console.log('3. App password is generated for "Mail" application');
  console.log('4. Less secure apps access might be disabled (use app passwords instead)');
}

main().catch(console.error);