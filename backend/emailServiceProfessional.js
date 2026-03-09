const sgMail = require('@sendgrid/mail');

class ProfessionalEmailService {
  constructor() {
    this.sendGridApiKey = process.env.SENDGRID_API_KEY || process.env.SENDGRID_KEY;
    this.fromEmail = process.env.SENDGRID_FROM || process.env.FROM_EMAIL || 'noreply@flownet.works';
    this.fromName = 'Flownet Workspaces';

    if (!this.sendGridApiKey) {
      console.log('⚠️ SENDGRID_API_KEY not configured - email sending will fail until it is set');
    } else {
      try {
        sgMail.setApiKey(this.sendGridApiKey.trim());
      } catch (err) {
        console.error('❌ Failed to initialize SendGrid client:', err.message);
      }
    }
  }

  // Test email service connection using SendGrid
  async testConnection() {
    if (!this.sendGridApiKey) {
      console.error('❌ Email service connection failed: SENDGRID_API_KEY is not set');
      return false;
    }

    try {
      await sgMail.send({
        to: this.fromEmail,
        from: {
          email: this.fromEmail,
          name: this.fromName,
        },
        subject: 'Flow-Space email test',
        html: '<p>This is a test email from Flow-Space backend (SendGrid connection check).</p>',
        text: 'This is a test email from Flow-Space backend (SendGrid connection check).',
      });
      console.log('✅ SendGrid connection successful');
      return true;
    } catch (error) {
      console.error('❌ Email service connection failed:', error.response?.body || error.message);
      return false;
    }
  }

  // Send verification email via SendGrid
  async sendVerificationEmail(toEmail, userName, verificationCode) {
    if (!this.sendGridApiKey) {
      const msg = 'SENDGRID_API_KEY is not configured';
      console.error('❌ Failed to send verification email:', msg);
      return { success: false, error: msg };
    }

    const msg = {
      to: toEmail,
      from: {
        email: this.fromEmail,
        name: this.fromName,
      },
      subject: 'Verify Your Email - Flownet Workspaces',
      html: this.buildVerificationEmailHtml(userName, verificationCode),
      text: this.buildVerificationEmailText(userName, verificationCode),
    };

    try {
      const [response] = await sgMail.send(msg);
      console.log('✅ SendGrid verification email sent successfully');
      return { success: true, statusCode: response.statusCode };
    } catch (error) {
      console.error('❌ Failed to send verification email via SendGrid:', error.response?.body || error.message);
      return { success: false, error: error.response?.body || error.message };
    }
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
