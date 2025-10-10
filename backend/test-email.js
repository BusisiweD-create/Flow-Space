const EmailService = require('./emailService');

async function testEmail() {
  console.log('🧪 Testing email sending...');
  
  const emailService = new EmailService();
  
  // Test SMTP connection
  console.log('🔌 Testing SMTP connection...');
  const isConnected = await emailService.testConnection();
  
  if (isConnected) {
    console.log('✅ SMTP connection successful!');
    
    // Test sending verification email
    console.log('📧 Sending test verification email...');
    const result = await emailService.sendVerificationEmail(
      'dhlaminibusisiwe30@gmail.com',
      'Busisiwe Dhlamini',
      '123456'
    );
    
    if (result.success) {
      console.log('✅ Test email sent successfully!');
      console.log('📧 Check your Gmail inbox for the verification email');
    } else {
      console.log('❌ Failed to send test email:', result.error);
    }
  } else {
    console.log('❌ SMTP connection failed');
  }
}

testEmail().catch(console.error);
