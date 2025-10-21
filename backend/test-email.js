const nodemailer = require('nodemailer');

// Test email configuration
const testEmail = async () => {
  console.log('📧 Testing email configuration...');
  
  // You need to replace 'your-app-password' with your actual Gmail App Password
  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
      user: 'dhlaminibusisiwe30@gmail.com',
      pass: 'bplc qegz kspg otfk ' // Replace with your Gmail App Password
    }
  });

  try {
    // Test the connection
    await transporter.verify();
    console.log('✅ Email configuration is valid!');
    
    // Send a test email
    const info = await transporter.sendMail({
      from: 'bdhlamini883@gmail.com',
      to: 'kasikash34@gmail.com',
      subject: 'Flow-Space Test Email',
      html: `
        <h2>Test Email from Flow-Space</h2>
        <p>If you receive this email, the email configuration is working correctly!</p>
        <p>Verification Code: <strong>123456</strong></p>
      `
    });
    
    console.log('✅ Test email sent successfully!');
    console.log('Message ID:', info.messageId);
    
  } catch (error) {
    console.error('❌ Email configuration failed:');
    console.error(error.message);
    
    if (error.code === 'EAUTH') {
      console.log('\n🔧 To fix this:');
      console.log('1. Go to your Google Account settings');
      console.log('2. Enable 2-Factor Authentication');
      console.log('3. Generate an App Password for "Mail"');
      console.log('4. Replace "your-app-password" in this file with the generated password');
    }
  }
};

testEmail();