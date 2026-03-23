const axios = require('axios');

const BASE_URL = 'http://localhost:8000';

async function testLogin() {
  try {
    console.log('Testing login with admin@flowspace.com / admin123...');
    
    const loginData = {
      email: 'admin@flowspace.com',
      password: 'admin123'
    };
    
    const response = await axios.post(`${BASE_URL}/api/v1/auth/login`, loginData);
    console.log('✅ Login successful:', response.data);
    
  } catch (error) {
    console.error('❌ Login failed:');
    console.error('Error message:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
    if (error.code) {
      console.error('Error code:', error.code);
    }
  }
}

testLogin();