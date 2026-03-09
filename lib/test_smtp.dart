import 'package:flutter/material.dart';
import 'services/smtp_email_service.dart';
import 'config/email_config.dart';

/// Simple test script to verify SMTP configuration
/// Run this by calling: flutter run lib/test_smtp.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🧪 Testing SMTP Configuration...\n');
  
  // Display current configuration
  debugPrint('📧 Current SMTP Configuration:');
  debugPrint('   Host: ${EmailConfig.smtpHost}');
  debugPrint('   Port: ${EmailConfig.smtpPort}');
  debugPrint('   Username: ${EmailConfig.smtpUsername}');
  debugPrint('   Password: ${'*' * EmailConfig.smtpPassword.length}');
  debugPrint('   Use TLS: ${EmailConfig.useTLS}');
  debugPrint('   Use SSL: ${EmailConfig.useSSL}');
  debugPrint('   From Email: ${EmailConfig.fromEmail}');
  debugPrint('   From Name: ${EmailConfig.fromName}');
  debugPrint('');
  
  // Test SMTP connection
  debugPrint('🔌 Testing SMTP Connection...');
  final emailService = SmtpEmailService();
  
  try {
    final isConnected = await emailService.testSmtpConnection();
    
    if (isConnected) {
      debugPrint('✅ SMTP connection successful!');
      
      // Test sending a verification email
      debugPrint('\n📧 Testing verification email...');
      const testEmail = EmailConfig.smtpUsername; // Send to self
      final testCode = emailService.generateVerificationCode();
      
      final emailSent = await emailService.sendVerificationEmail(
        toEmail: testEmail,
        userName: 'Test User',
        verificationCode: testCode,
      );
      
      if (emailSent) {
        debugPrint('✅ Verification email sent successfully!');
        debugPrint('   Check your inbox for the verification code: $testCode');
      } else {
        debugPrint('❌ Failed to send verification email');
      }
    } else {
      debugPrint('❌ SMTP connection failed');
      debugPrint('\n🔧 Troubleshooting tips:');
      debugPrint('   1. Check your email credentials');
      debugPrint('   2. Ensure 2FA is enabled and you\'re using an app password');
      debugPrint('   3. Verify SMTP host and port settings');
      debugPrint('   4. Check firewall settings');
      debugPrint('   5. Try a different email provider');
    }
  } catch (e) {
    debugPrint('❌ Error testing SMTP: $e');
    debugPrint('\n🔧 Common issues:');
    debugPrint('   - Invalid credentials');
    debugPrint('   - Network connectivity issues');
    debugPrint('   - Incorrect SMTP settings');
    debugPrint('   - Email provider restrictions');
  }
  
  debugPrint('\n🏁 SMTP test completed');
}
