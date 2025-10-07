const EmailService = require('./emailService');

async function testSpecificEmail() {
  console.log('🧪 Testing email for mabotsanaomi@gmail.com...');
  
  const emailService = new EmailService();
  
  // Test sending verification email to the specific user
  const result = await emailService.sendVerificationEmail(
    'mabotsanaomi@gmail.com',
    'Mabotsa Naomi',
    '123456'
  );
  
  if (result.success) {
    console.log('✅ Verification email sent successfully to mabotsanaomi@gmail.com!');
    console.log('📧 Check the Gmail inbox for mabotsanaomi@gmail.com');
    console.log('📧 Message ID:', result.messageId);
  } else {
    console.log('❌ Failed to send email:', result.error);
  }
}

testSpecificEmail().catch(console.error);
