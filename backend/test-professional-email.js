const ProfessionalEmailService = require('./emailServiceProfessional');

async function testProfessionalEmailService() {
  console.log('🧪 Testing Professional Email Service...');
  
  const emailService = new ProfessionalEmailService();
  
  // Test connection
  console.log('🔌 Testing email service connection...');
  const connectionResult = await emailService.testConnection();
  
  if (!connectionResult) {
    console.log('❌ Email service connection failed');
    console.log('💡 Make sure to set up SendGrid API key or fix Gmail security warning');
    return;
  }
  
  // Test sending email
  console.log('📧 Testing email sending...');
  const testEmail = 'dhlaminibusisiwe30@gmail.com'; // Your email for testing
  const testName = 'Busisiwe Dhlamini';
  const testCode = '123456';
  
  const emailResult = await emailService.sendVerificationEmail(testEmail, testName, testCode);
  
  if (emailResult.success) {
    console.log('✅ Email sent successfully!');
    console.log('Message ID:', emailResult.messageId);
    console.log('📬 Check your email inbox for the verification email');
  } else {
    console.log('❌ Email sending failed:', emailResult.error);
  }
}

testProfessionalEmailService();
