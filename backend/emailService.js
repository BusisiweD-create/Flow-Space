const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    // Gmail SMTP configuration
    this.transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false, // true for 465, false for other ports
      auth: {
        user: 'dhlaminibusisiwe30@gmail.com',
        pass: 'bplcqegzkspgotfk' // Your app password
      }
    });
  }

  // Test SMTP connection
  async testConnection() {
    try {
      await this.transporter.verify();
      console.log('✅ SMTP connection successful');
      return true;
    } catch (error) {
      console.error('❌ SMTP connection failed:', error.message);
      return false;
    }
  }

  // Send verification email
  async sendVerificationEmail(toEmail, userName, verificationCode) {
    try {
      const mailOptions = {
        from: {
          name: 'Flownet Workspaces',
          address: 'dhlaminibusisiwe30@gmail.com'
        },
        to: toEmail,
        subject: 'Verify Your Email - Flownet Workspaces',
        html: this.buildVerificationEmailHtml(userName, verificationCode)
      };

      const result = await this.transporter.sendMail(mailOptions);
      console.log('✅ Verification email sent successfully:', result.messageId);
      return { success: true, messageId: result.messageId };
    } catch (error) {
      console.error('❌ Failed to send verification email:', error.message);
      return { success: false, error: error.message };
    }
  }

  // Send password reset email
  async sendPasswordResetEmail(toEmail, userName, resetLink) {
    try {
      const mailOptions = {
        from: {
          name: 'Flownet Workspaces',
          address: 'dhlaminibusisiwe30@gmail.com'
        },
        to: toEmail,
        subject: 'Reset Your Password - Flownet Workspaces',
        html: this.buildPasswordResetEmailHtml(userName, resetLink)
      };

      const result = await this.transporter.sendMail(mailOptions);
      console.log('✅ Password reset email sent successfully:', result.messageId);
      return { success: true, messageId: result.messageId };
    } catch (error) {
      console.error('❌ Failed to send password reset email:', error.message);
      return { success: false, error: error.message };
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

  // Build password reset email HTML
  buildPasswordResetEmailHtml(userName, resetLink) {
    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset</title>
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
            background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .content {
            padding: 40px 30px;
        }
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 25px;
            font-weight: bold;
            margin: 20px 0;
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
            <h1>🔐 Password Reset Request</h1>
        </div>
        
        <div class="content">
            <h2>Reset Your Password</h2>
            <p>Hi <strong>${userName}</strong>,</p>
            <p>We received a request to reset your password for your Flownet Workspaces account.</p>
            
            <a href="${resetLink}" class="button">Reset Password</a>
            
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; color: #667eea;">${resetLink}</p>
            
            <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; color: #856404;">
                <strong>🔒 Security Note:</strong> This link will expire in 1 hour for your security. If you didn't request a password reset, please ignore this email.
            </div>
            
            <p>Best regards,<br>
            <strong>The Flownet Workspaces Team</strong></p>
        </div>
        
        <div class="footer">
            <p>This email was sent because you requested a password reset.</p>
            <p>© ${new Date().getFullYear()} Flownet Workspaces. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    `;
  }
}

module.exports = EmailService;
