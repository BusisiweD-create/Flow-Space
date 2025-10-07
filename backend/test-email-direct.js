const EmailService = require('./emailService');

async function testEmail() {
  console.log('🧪 Testing email service directly...');
  
  const emailService = new EmailService();
  
  // Test SMTP connection
  console.log('🔌 Testing SMTP connection...');
  const connectionTest = await emailService.testConnection();
  
  if (!connectionTest) {
    console.log('❌ SMTP connection failed. Exiting.');
    return;
  }
  
  // Test sending verification email
  console.log('📧 Testing verification email...');
  const emailResult = await emailService.sendVerificationEmail(
    'dhlaminibusisiwe30@gmail.com', // Send to self for testing
    'Busisiwe Dhlamini',
    '123456'
  );
  
  if (emailResult.success) {
    console.log('✅ Verification email sent successfully!');
    console.log('   Message ID:', emailResult.messageId);
  } else {
    console.log('❌ Failed to send verification email:', emailResult.error);
  }
  
  console.log('🏁 Email test completed');
}

testEmail().catch(console.error);
