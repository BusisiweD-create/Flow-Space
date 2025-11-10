const axios = require('axios');

const BASE_URL = 'http://localhost:8000';

async function testUserDeletion() {
  try {
    console.log('🧪 Testing user deletion endpoint...');
    
    // First, let's get an admin token by logging in with a known working user
    console.log('\n🔐 Logging in as Thabang.Nkabinde@khonology.com...');
    const loginResponse = await axios.post(`${BASE_URL}/api/v1/auth/login`, {
      email: 'Thabang.Nkabinde@khonology.com',
      password: 'password123' // Try common password
    });
    
    const authToken = loginResponse.data.data.token;
    console.log('✅ Login successful');
    
    // Get list of users to find one to delete
    console.log('\n👥 Getting users list...');
    const usersResponse = await axios.get(`${BASE_URL}/api/v1/users`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const users = usersResponse.data.data;
    console.log(`📋 Found ${users.length} users`);
    
    if (users.length === 0) {
      console.log('❌ No users found in database');
      return;
    }
    
    // Display all users
    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email} (${user.name}, ${user.role}) - ID: ${user.id}`);
    });
    
    // Find a test user to delete (not the current user)
    const testUser = users.find(user => user.email !== 'Thabang.Nkabinde@khonology.com');
    
    if (!testUser) {
      console.log('❌ No test users found to delete (only current user exists)');
      return;
    }
    
    console.log(`\n🗑️  Attempting to delete user: ${testUser.email} (ID: ${testUser.id})`);
    
    // Test the DELETE endpoint
    const deleteResponse = await axios.delete(`${BASE_URL}/api/v1/users/${testUser.id}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    console.log('✅ User deletion successful!');
    console.log('Response:', deleteResponse.data);
    
    // Verify the user was actually deleted
    console.log('\n🔍 Verifying user was deleted...');
    const updatedUsersResponse = await axios.get(`${BASE_URL}/api/v1/users`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    const updatedUsers = updatedUsersResponse.data.data;
    const userStillExists = updatedUsers.some(user => user.id === testUser.id);
    
    if (!userStillExists) {
      console.log('✅ User successfully removed from database');
      console.log(`📊 Before: ${users.length} users, After: ${updatedUsers.length} users`);
    } else {
      console.log('❌ User still exists in database');
    }
    
  } catch (error) {
    console.error('❌ Error testing user deletion:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Message:', error.message);
    }
  }
}

testUserDeletion();