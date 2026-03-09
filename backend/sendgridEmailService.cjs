const nodemailer = require('nodemailer');
const sgMail = require('@sendgrid/mail');

class SendGridEmailService {
  constructor() {
    // Validate API key format
    if (!process.env.SENDGRID_API_KEY || !process.env.SENDGRID_API_KEY.startsWith('SG.')) {
      console.error('❌ Invalid SendGrid API key format');
      console.error('💡 Expected format: SG.xxxxxxxxxxxx.yyyyyyyyyyyyyyyyyyyyyyyy');
      console.error('💡 Current key:', process.env.SENDGRID_API_KEY ? 'Set but invalid format' : 'Not set');
      throw new Error('Invalid SENDGRID_API_KEY format');
    }

    this.sendgrid = sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    this.fromName = process.env.FROM_NAME || 'Flownet Workspaces';
    this.fromEmail = process.env.FROM_EMAIL || 'dhlamininaomi1@gmail.com';
    this.replyTo = process.env.EMAIL_REPLY_TO || this.fromEmail;
    
    // Enhanced validation
    console.log('📧 SendGrid Configuration:');
    console.log('  API Key Valid:', !!process.env.SENDGRID_API_KEY);
    console.log('  API Key Format:', process.env.SENDGRID_API_KEY?.startsWith('SG.') ? 'Valid' : 'Invalid');
    console.log('  FROM_EMAIL env var:', process.env.FROM_EMAIL);
    console.log('  Final fromEmail:', this.fromEmail);
    console.log('  fromName:', this.fromName);
    
    // Validate sender on initialization
    this.validateSenderConfiguration();
  }

  // Test SendGrid connection
  async testConnection() {
    try {
      if (!process.env.SENDGRID_API_KEY) {
        console.log('⚠️  SENDGRID_API_KEY not configured');
        return false;
      }
      
      // Test sender validation
      const isValid = await this.validateSenderConfiguration();
      return isValid;
    } catch (error) {
      console.error('❌ SendGrid initialization failed:', error.message);
      return false;
    }
  }

  // Validate sender configuration
  async validateSenderConfiguration() {
    try {
      console.log('🔍 Validating SendGrid sender configuration...');
      
      // Test with a minimal email to self
      const testEmail = {
        to: this.fromEmail,
        from: {
          name: this.fromName,
          email: this.fromEmail
        },
        subject: 'SendGrid Configuration Test',
        html: '<p>This is a test to verify sender configuration.</p>',
        category: 'configuration_test'
      };

      const result = await this.sendgrid.send(testEmail);
      console.log('✅ Sender configuration validated:', result[0].messageId);
      return true;
    } catch (error) {
      console.error('❌ Sender configuration failed:', error.message);
      
      if (error.response) {
        console.error('📧 SendGrid API Response:', {
          status: error.response.status,
          body: error.response.body
        });
        
        // Specific error guidance
        if (error.response.status === 401) {
          console.error('🔑 SendGrid Error: Invalid API Key');
          console.error('💡 Fix: Check SENDGRID_API_KEY in environment variables');
        } else if (error.response.status === 403) {
          console.error('🚫 SendGrid Error: Sender not authorized');
          console.error('💡 Solutions:');
          console.error('   1. Verify sender email in SendGrid dashboard');
          console.error('   2. Complete domain authentication (SPF, DKIM, DMARC)');
          console.error('   3. Check API key has "Mail Send" permissions');
          console.error('   4. Ensure FROM_EMAIL matches verified sender exactly');
          console.error('   5. Check if sender is on a dedicated IP (if required)');
        } else if (error.response.status === 400) {
          console.error('📧 SendGrid Error: Bad request');
          console.error('💡 Fix: Check FROM_EMAIL format and request structure');
        }
      }
      
      return false;
    }
  }

  // Send verification email
  async sendVerificationEmail(toEmail, userName, verificationCode) {
    try {
      console.log(`📧 Sending verification email to: ${toEmail}`);
      
      const mailOptions = {
        to: toEmail,
        from: {
          name: this.fromName,
          email: this.fromEmail
        },
        subject: 'Verify Your Email - Flownet Workspaces',
        html: this.buildVerificationEmailHtml(userName, verificationCode),
        replyTo: this.replyTo,
        category: 'email_verification'
      };

      const result = await this.sendgrid.send(mailOptions);
      console.log('✅ Verification email sent successfully via SendGrid:', result[0].messageId);
      return { success: true, messageId: result[0].messageId };
    } catch (error) {
      console.error('❌ Failed to send verification email via SendGrid:', error.message);
      
      // Enhanced error debugging
      if (error.response) {
        console.error('📧 SendGrid API Response:', {
          status: error.response.status,
          body: error.response.body
        });
        
        // Don't fallback on 403 - it's a configuration issue
        if (error.response.status === 403) {
          console.error('� 403 Forbidden - This is a configuration issue, not a network issue');
          console.error('💡 Fix sender configuration before retrying');
          return { 
            success: false, 
            error: 'Sender not authorized. Check SendGrid configuration.',
            requiresConfigurationFix: true 
          };
        }
        
        // Specific error guidance for other errors
        if (error.response.status === 401) {
          console.error('� SendGrid Error: Invalid API Key');
          console.error('💡 Fix: Check SENDGRID_API_KEY in Render environment variables');
        } else if (error.response.status === 400) {
          console.error('📧 SendGrid Error: Bad request - check FROM_EMAIL format');
          console.error('💡 Fix: Ensure FROM_EMAIL matches verified sender');
        }
      } else if (error.code === 'ENOTFOUND') {
        console.error('🌐 SendGrid Error: Network connection failed');
        console.error('💡 Fix: Check internet connection and firewall settings');
      }
      
      // Fallback to SMTP for non-403 errors
      console.log('🔄 Attempting SMTP fallback...');
      return await this.sendViaSmtpFallback(toEmail, userName, verificationCode);
    }
  }

  // Fallback to SMTP
  async sendViaSmtpFallback(toEmail, userName, verificationCode) {
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_SECURE === 'true' || false,
        auth: {
          user: process.env.SMTP_USER,
          pass: (process.env.SMTP_PASS || '').replace(/\s+/g, '')
        }
      });

      const mailOptions = {
        from: {
          name: this.fromName,
          address: process.env.SMTP_FROM_EMAIL || process.env.SMTP_USER
        },
        to: toEmail,
        subject: 'Verify Your Email - Flownet Workspaces',
        html: this.buildVerificationEmailHtml(userName, verificationCode),
        replyTo: this.replyTo
      };

      const result = await transporter.sendMail(mailOptions);
      console.log('✅ Verification email sent via SMTP fallback:', result.messageId);
      return { success: true, messageId: result.messageId };
    } catch (error) {
      console.error('❌ SMTP fallback also failed:', error.message);
      return { success: false, error: error.message };
    }
  }

  buildVerificationEmailHtml(userName, verificationCode) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verification</title>
        <style>
          body { font-family: 'Poppins', sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
          .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .header { text-align: center; margin-bottom: 30px; }
          .logo { font-size: 24px; font-weight: bold; color: #C10D00; }
          .content { margin-bottom: 30px; }
          .code { background-color: #f8f9fa; border: 2px solid #e9ecef; border-radius: 8px; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 4px; margin: 20px 0; color: #C10D00; }
          .footer { text-align: center; color: #6c757d; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">Flownet Workspaces</div>
          </div>
          <div class="content">
            <h2>Hello ${userName},</h2>
            <p>Thank you for signing up! Please use the verification code below to activate your account:</p>
            <div class="code">${verificationCode}</div>
            <p>This code will expire in 24 hours.</p>
            <p>If you didn't request this verification, please ignore this email.</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 Flownet Workspaces. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }
}

module.exports = SendGridEmailService;
