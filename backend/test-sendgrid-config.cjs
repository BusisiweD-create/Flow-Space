#!/usr/bin/env node

// SendGrid Configuration Test Script
// Run this script to test SendGrid setup before deployment

require('dotenv/config');
const SendGridEmailService = require('./sendgridEmailService.js').default;

console.log('🔧 SendGrid Configuration Test');
console.log('================================');

// Test 1: Environment Variables
console.log('\n📋 Step 1: Checking Environment Variables');
console.log('-------------------------------------------');

console.log('SENDGRID_API_KEY:', process.env.SENDGRID_API_KEY ? 
  `✅ Set (${process.env.SENDGRID_API_KEY.substring(0, 20)}...)` : 
  '❌ Not set');

console.log('FROM_EMAIL:', process.env.FROM_EMAIL || '❌ Not set');
console.log('FROM_NAME:', process.env.FROM_NAME || '❌ Not set');

// Validate API key format
const apiKeyValid = process.env.SENDGRID_API_KEY?.startsWith('SG.');
console.log('API Key Format:', apiKeyValid ? '✅ Valid (SG.xxxx...)' : '❌ Invalid');

// Test 2: SendGrid Service Initialization
console.log('\n🔍 Step 2: Testing SendGrid Service');
console.log('----------------------------------------');

try {
  // Create service instance - the constructor runs validation automatically
  const emailService = new SendGridEmailService();
  console.log('✅ SendGrid service initialized successfully');
  
  // Test 3: Connection and Sender Validation
  console.log('\n📧 Step 3: Testing Connection & Sender');
  console.log('--------------------------------------');
  
  emailService.testConnection().then(result => {
    console.log('Connection test result:', result ? '✅ PASSED' : '❌ FAILED');
    
    if (result) {
      console.log('\n🎉 SendGrid Configuration is Ready!');
      console.log('=====================================');
      console.log('✅ API Key: Valid format');
      console.log('✅ Sender: Verified');
      console.log('✅ Connection: Successful');
      console.log('\n📝 Next Steps:');
      console.log('1. Deploy to production');
      console.log('2. Test user registration');
      console.log('3. Monitor email delivery logs');
    } else {
      console.log('\n❌ SendGrid Configuration Failed!');
      console.log('================================');
      console.log('🔧 Fix Required:');
      console.log('1. Check SendGrid dashboard for sender verification');
      console.log('2. Verify API key permissions');
      console.log('3. Complete domain authentication (SPF, DKIM, DMARC)');
      console.log('4. Ensure FROM_EMAIL matches verified sender');
    }
  }).catch(error => {
    console.error('❌ Connection test failed:', error.message);
  });
  
} catch (error) {
  console.error('❌ Failed to initialize SendGrid service:', error.message);
  
  if (error.message.includes('Invalid SENDGRID_API_KEY format')) {
    console.log('\n💡 API Key Fix:');
    console.log('1. Go to SendGrid dashboard');
    console.log('2. Settings → API Keys → Create API Key');
    console.log('3. Ensure key starts with "SG."');
    console.log('4. Set SENDGRID_API_KEY in environment variables');
  }
}

console.log('\n📚 Additional Resources:');
console.log('========================');
console.log('SendGrid Dashboard: https://app.sendgrid.com');
console.log('API Documentation: https://docs.sendgrid.com/api-reference');
console.log('Sender Authentication: https://docs.sendgrid.com/for-developers/sending-email/sender-identity');
