const EmailService = require('./emailService');

async function testEmailService() {
  console.log('🧪 Testing Email Service...');
  
  const emailService = new EmailService();
  
  // Test connection
  console.log('🔌 Testing SMTP connection...');
  const connectionResult = await emailService.testConnection();
  
  if (!connectionResult) {
    console.log('❌ SMTP connection failed, stopping test');
    return;
  }
  
  // Test sending email to a different address
  console.log('📧 Testing email sending...');
  const testEmail = 'test@example.com'; // This will fail, but we can see the error
  const testName = 'Test User';
  const testCode = '123456';
  
  const emailResult = await emailService.sendVerificationEmail(testEmail, testName, testCode);
  
  if (emailResult.success) {
    console.log('✅ Email sent successfully!');
    console.log('Message ID:', emailResult.messageId);
  } else {
    console.log('❌ Email sending failed:', emailResult.error);
  }
}

testEmailService();
