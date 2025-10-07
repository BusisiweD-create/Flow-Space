const nodemailer = require('nodemailer');
const sgMail = require('@sendgrid/mail');

class ProfessionalEmailService {
  constructor() {
    // SendGrid configuration
    this.sendGridApiKey = process.env.SENDGRID_API_KEY || 'SG.your-sendgrid-api-key-here';
    this.fromEmail = process.env.FROM_EMAIL || 'noreply@flownet.works';
    this.fromName = 'Flownet Workspaces';
    
    // Fallback Gmail configuration (if SendGrid fails)
    this.gmailTransporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth: {
        user: 'dhlaminibusisiwe30@gmail.com',
        pass: 'bplcqegzkspgotfk'
      }
    });
    
    // Initialize SendGrid
    if (this.sendGridApiKey && this.sendGridApiKey !== 'SG.your-sendgrid-api-key-here') {
      sgMail.setApiKey(this.sendGridApiKey);
      this.useSendGrid = true;
    } else {
      this.useSendGrid = false;
      console.log('⚠️ SendGrid API key not configured, using Gmail fallback');
    }
  }

  // Test email service connection
  async testConnection() {
    try {
      if (this.useSendGrid) {
        // Test SendGrid
        const msg = {
          to: 'test@example.com',
          from: this.fromEmail,
          subject: 'Test Email',
          text: 'This is a test email'
        };
        await sgMail.send(msg);
        console.log('✅ SendGrid connection successful');
        return true;
      } else {
        // Test Gmail
        await this.gmailTransporter.verify();
        console.log('✅ Gmail fallback connection successful');
        return true;
      }
    } catch (error) {
      console.error('❌ Email service connection failed:', error.message);
      return false;
    }
  }

  // Send verification email with fallback
  async sendVerificationEmail(toEmail, userName, verificationCode) {
    try {
      if (this.useSendGrid) {
        return await this.sendWithSendGrid(toEmail, userName, verificationCode);
      } else {
        return await this.sendWithGmail(toEmail, userName, verificationCode);
      }
    } catch (error) {
      console.error('❌ Failed to send verification email:', error.message);
      
      // Try fallback if primary method failed
      if (this.useSendGrid) {
        console.log('🔄 Trying Gmail fallback...');
        return await this.sendWithGmail(toEmail, userName, verificationCode);
      }
      
      return { success: false, error: error.message };
    }
  }

  // Send with SendGrid
  async sendWithSendGrid(toEmail, userName, verificationCode) {
    const msg = {
      to: toEmail,
      from: {
        email: this.fromEmail,
        name: this.fromName
      },
      subject: 'Verify Your Email - Flownet Workspaces',
      html: this.buildVerificationEmailHtml(userName, verificationCode),
      text: this.buildVerificationEmailText(userName, verificationCode)
    };

    const result = await sgMail.send(msg);
    console.log('✅ SendGrid verification email sent successfully');
    return { success: true, messageId: result[0].headers['x-message-id'] };
  }

  // Send with Gmail (fallback)
  async sendWithGmail(toEmail, userName, verificationCode) {
    const mailOptions = {
      from: {
        name: this.fromName,
        address: 'dhlaminibusisiwe30@gmail.com'
      },
      to: toEmail,
      subject: 'Verify Your Email - Flownet Workspaces',
      html: this.buildVerificationEmailHtml(userName, verificationCode)
    };

    const result = await this.gmailTransporter.sendMail(mailOptions);
    console.log('✅ Gmail verification email sent successfully');
    return { success: true, messageId: result.messageId };
  }

  // Build verification email HTML
  buildVerificationEmailHtml(userName, verificationCode) {
    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 300;
        }
        .content {
            padding: 40px 30px;
        }
        .verification-code {
            background-color: #f8f9fa;
            border: 2px dashed #667eea;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
        }
        .verification-code h2 {
            color: #667eea;
            margin: 0;
            font-size: 32px;
            letter-spacing: 3px;
            font-family: 'Courier New', monospace;
        }
        .instructions {
            background-color: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 15px;
            margin: 20px 0;
        }
        .security-note {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            color: #856404;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Welcome to Flownet Workspaces</h1>
        </div>
        
        <div class="content">
            <h2>Verify Your Email Address</h2>
            <p>Hi <strong>${userName}</strong>,</p>
            <p>Thank you for registering with Flownet Workspaces! To complete your account setup, please verify your email address using the code below:</p>
            
            <div class="verification-code">
                <h2>${verificationCode}</h2>
            </div>
            
            <div class="instructions">
                <h3>📋 Instructions:</h3>
                <ol>
                    <li>Copy the verification code above</li>
                    <li>Return to the Flownet Workspaces app</li>
                    <li>Enter the code in the verification screen</li>
                    <li>Click "Verify Email" to complete your registration</li>
                </ol>
            </div>
            
            <div class="security-note">
                <strong>🔒 Security Note:</strong> This verification code will expire in 15 minutes for your security. If you didn't create an account with Flownet Workspaces, please ignore this email.
            </div>
            
            <p>If you have any questions or need assistance, please don't hesitate to contact our support team at support@flownet.works.</p>
            
            <p>Best regards,<br>
            <strong>The Flownet Workspaces Team</strong></p>
        </div>
        
        <div class="footer">
            <p>This email was sent because you registered for a Flownet Workspaces account.</p>
            <p>© ${new Date().getFullYear()} Flownet Workspaces. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    `;
  }

  // Build verification email text version
  buildVerificationEmailText(userName, verificationCode) {
    return `
Welcome to Flownet Workspaces!

Hi ${userName},

Thank you for registering with Flownet Workspaces! To complete your account setup, please verify your email address using the code below:

VERIFICATION CODE: ${verificationCode}

Instructions:
1. Copy the verification code above
2. Return to the Flownet Workspaces app
3. Enter the code in the verification screen
4. Click "Verify Email" to complete your registration

Security Note: This verification code will expire in 15 minutes for your security. If you didn't create an account with Flownet Workspaces, please ignore this email.

If you have any questions or need assistance, please contact our support team at support@flownet.works.

Best regards,
The Flownet Workspaces Team

---
This email was sent because you registered for a Flownet Workspaces account.
© ${new Date().getFullYear()} Flownet Workspaces. All rights reserved.
    `;
  }
}

module.exports = ProfessionalEmailService;
