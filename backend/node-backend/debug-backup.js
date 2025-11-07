const axios = require('axios');

// Test configuration
const BASE_URL = 'http://localhost:8000';
const TEST_USER = {
  email: 'admin@flowspace.com',
  password: 'password'
};

// Helper function to login and get token
async function login() {
  try {
    console.log('🔧 Attempting login with:', TEST_USER.email);
    
    const response = await axios.post(`${BASE_URL}/api/v1/auth/login`, {
      email: TEST_USER.email,
      password: TEST_USER.password
    }, {
      timeout: 5000,
      validateStatus: function (status) {
        return status >= 200 && status < 600; // Accept all status codes
      }
    });
    
    console.log('📊 Login response status:', response.status);
    console.log('📊 Login response data:', JSON.stringify(response.data, null, 2));
    
    if (response.status === 200 && response.data.token) {
      console.log('✅ Login successful');
      return response.data.token;
    } else {
      console.log('❌ Login failed with status:', response.status);
      return null;
    }
  } catch (error) {
    console.error('❌ Login error:', error.message);
    if (error.response) {
      console.error('❌ Response status:', error.response.status);
      console.error('❌ Response data:', error.response.data);
    }
    return null;
  }
}

// Test simple API endpoint to check if server is responding
async function testServerConnection() {
  try {
    console.log('🔧 Testing server connection...');
    
    const response = await axios.get(`${BASE_URL}/api/v1/auth/health`, {
      timeout: 3000,
      validateStatus: function (status) {
        return status >= 200 && status < 600;
      }
    });
    
    console.log('📊 Server response status:', response.status);
    console.log('📊 Server response data:', response.data);
    
    return response.status === 200;
  } catch (error) {
    console.error('❌ Server connection error:', error.message);
    return false;
  }
}

// Main debug function
async function debugLogin() {
  console.log('🚀 Starting debug session...\n');
  
  // Step 1: Test server connection
  const serverConnected = await testServerConnection();
  if (!serverConnected) {
    console.log('❌ Cannot connect to server');
    return;
  }
  
  console.log('\n🔧 Server is responding, testing login...\n');
  
  // Step 2: Test login
  const token = await login();
  
  if (token) {
    console.log('\n✅ Login successful! Token:', token.substring(0, 20) + '...');
    
    // Step 3: Test system endpoints
    await testSystemEndpoints(token);
  } else {
    console.log('\n❌ Login failed. Possible issues:');
    console.log('   1. Admin user may not exist in database');
    console.log('   2. Wrong password');
    console.log('   3. Database connection issues');
    console.log('   4. User account may be inactive');
  }
}

// Test system endpoints
async function testSystemEndpoints(token) {
  try {
    console.log('\n🔧 Testing system endpoints...');
    
    // Test system health endpoint
    const healthResponse = await axios.get(`${BASE_URL}/api/v1/system/health`, {
      headers: { 'Authorization': `Bearer ${token}` },
      validateStatus: function (status) {
        return status >= 200 && status < 600;
      }
    });
    
    console.log('📊 System health status:', healthResponse.status);
    console.log('📊 System health data:', JSON.stringify(healthResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ System endpoint error:', error.message);
  }
}

// Run the debug
console.log('🔍 Debugging backup functionality...');
debugLogin().catch(error => {
  console.error('Debug failed:', error);
});