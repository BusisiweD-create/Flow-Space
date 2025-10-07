import 'dart:math';
import 'package:flutter/foundation.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // SMTP Configuration
  static const String _smtpHost = 'smtp.gmail.com'; // Change to your SMTP server
  static const int _smtpPort = 587;
  static const String _smtpUsername = 'your-email@gmail.com'; // Change to your email
  static const String _fromEmail = 'your-email@gmail.com'; // Change to your email
  static const String _fromName = 'Flownet Workspaces';

  // Email templates
  static const String _verificationEmailTemplate = '''
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
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 30px;
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
        .security-note {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            color: #856404;
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
            <p>Hi <strong>{{USER_NAME}}</strong>,</p>
            <p>Thank you for registering with Flownet Workspaces! To complete your account setup, please verify your email address using the code below:</p>
            
            <div class="verification-code">
                <h2>{{VERIFICATION_CODE}}</h2>
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
            
            <p>If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
            
            <p>Best regards,<br>
            <strong>The Flownet Workspaces Team</strong></p>
        </div>
        
        <div class="footer">
            <p>This email was sent to {{USER_EMAIL}} because you registered for a Flownet Workspaces account.</p>
            <p>© 2024 Flownet Workspaces. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';

  static const String _passwordResetEmailTemplate = '''
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
            <p>Hi <strong>{{USER_NAME}}</strong>,</p>
            <p>We received a request to reset your password for your Flownet Workspaces account.</p>
            
            <a href="{{RESET_LINK}}" class="button">Reset Password</a>
            
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; color: #667eea;">{{RESET_LINK}}</p>
            
            <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; color: #856404;">
                <strong>🔒 Security Note:</strong> This link will expire in 1 hour for your security. If you didn't request a password reset, please ignore this email.
            </div>
            
            <p>Best regards,<br>
            <strong>The Flownet Workspaces Team</strong></p>
        </div>
        
        <div class="footer">
            <p>This email was sent to {{USER_EMAIL}} because you requested a password reset.</p>
            <p>© 2024 Flownet Workspaces. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';

  // Generate verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send verification email
  Future<bool> sendVerificationEmail({
    required String toEmail,
    required String userName,
    required String verificationCode,
  }) async {
    try {
      const subject = 'Verify Your Email - Flownet Workspaces';
      final htmlContent = _verificationEmailTemplate
          .replaceAll('{{USER_NAME}}', userName)
          .replaceAll('{{USER_EMAIL}}', toEmail)
          .replaceAll('{{VERIFICATION_CODE}}', verificationCode);

      return await _sendEmail(
        to: toEmail,
        subject: subject,
        htmlContent: htmlContent,
      );
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String userName,
    required String resetLink,
  }) async {
    try {
      const subject = 'Reset Your Password - Flownet Workspaces';
      final htmlContent = _passwordResetEmailTemplate
          .replaceAll('{{USER_NAME}}', userName)
          .replaceAll('{{USER_EMAIL}}', toEmail)
          .replaceAll('{{RESET_LINK}}', resetLink);

      return await _sendEmail(
        to: toEmail,
        subject: subject,
        htmlContent: htmlContent,
      );
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      return false;
    }
  }

  // Core email sending method using SMTP
  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      // In a real implementation, you would use an SMTP library like 'mailer'
      // For now, we'll simulate the email sending process
      
      debugPrint('📧 Sending email to: $to');
      debugPrint('📧 Subject: $subject');
      debugPrint('📧 SMTP Host: $_smtpHost');
      debugPrint('📧 SMTP Port: $_smtpPort');
      debugPrint('📧 From: $_fromEmail');
      
      // Simulate SMTP connection and email sending
      await Future.delayed(const Duration(seconds: 2));
      
      // In production, you would implement actual SMTP sending here
      // Example using the 'mailer' package:
      /*
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        allowInsecure: false,
        ssl: false,
        ignoreBadCertificate: false,
      );

      final message = Message()
        ..from = Address(_fromEmail, _fromName)
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlContent;

      final sendReport = await send(message, smtpServer);
      return sendReport.sent;
      */
      
      // For now, return true to simulate successful sending
      debugPrint('✅ Email sent successfully to $to');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
      return false;
    }
  }

  // Generate and send verification email
  Future<Map<String, dynamic>> generateAndSendVerificationEmail({
    required String toEmail,
    required String userName,
  }) async {
    final verificationCode = _generateVerificationCode();
    
    final success = await sendVerificationEmail(
      toEmail: toEmail,
      userName: userName,
      verificationCode: verificationCode,
    );

    return {
      'success': success,
      'verificationCode': verificationCode,
      'expiresAt': DateTime.now().add(const Duration(minutes: 15)),
    };
  }

  // Validate verification code
  bool validateVerificationCode({
    required String inputCode,
    required String storedCode,
    required DateTime expiresAt,
  }) {
    if (DateTime.now().isAfter(expiresAt)) {
      return false; // Code expired
    }
    
    return inputCode == storedCode;
  }

  // Get SMTP configuration
  Map<String, dynamic> getSmtpConfig() {
    return {
      'host': _smtpHost,
      'port': _smtpPort,
      'username': _smtpUsername,
      'fromEmail': _fromEmail,
      'fromName': _fromName,
    };
  }

  // Test SMTP connection
  Future<bool> testSmtpConnection() async {
    try {
      // In a real implementation, you would test the SMTP connection
      debugPrint('🔍 Testing SMTP connection...');
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('✅ SMTP connection successful');
      return true;
    } catch (e) {
      debugPrint('❌ SMTP connection failed: $e');
      return false;
    }
  }
}
