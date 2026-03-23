const axios = require('axios');

const BASE_URL = 'http://localhost:8000';

async function testUserDeletion() {
  try {
    console.log('🧪 Testing user deletion functionality...');
    
    // Step 1: Login as admin (systemAdmin)
    console.log('\n1. Logging in as admin@flowspace.com...');
    const loginData = {
      email: 'admin@flowspace.com',
      password: 'admin123'
    };
    const loginResponse = await axios.post(`${BASE_URL}/api/v1/auth/login`, loginData);
    
    if (!loginResponse.data.success) {
      console.log('❌ Login failed:', loginResponse.data.error);
      return;
    }
    
    const token = loginResponse.data.data.token;
    console.log('✅ Login successful');
    
    // Step 2: Get all users to find a test user to delete
    console.log('\n2. Getting list of users...');
    const usersResponse = await axios.get(`${BASE_URL}/api/v1/users`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (!usersResponse.data.success) {
      console.log('❌ Failed to get users:', usersResponse.data.error);
      return;
    }
    
    // Check if the data structure contains users array
    const users = usersResponse.data.data || [];
    console.log(`📊 Found ${users.length} users`);
    
    // Find a non-admin user to delete (not systemAdmin or admin)
    const userToDelete = users.find(user => 
      user.role !== 'systemAdmin' && user.role !== 'admin'
    );
    
    if (!userToDelete) {
      console.log('⚠️ No non-admin users found to delete');
      return;
    }
    
    console.log(`🎯 Selected user to delete: ${userToDelete.email} (${userToDelete.role})`);
    
    // Step 3: Delete the user
    console.log(`\n3. Deleting user ${userToDelete.email}...`);
    const deleteResponse = await axios.delete(`${BASE_URL}/api/v1/users/${userToDelete.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (!deleteResponse.data.success) {
      console.log('❌ Delete failed:', deleteResponse.data.error);
      return;
    }
    
    console.log('✅ User deleted successfully:', deleteResponse.data.message);
    
    // Step 4: Verify user is gone
    console.log('\n4. Verifying user is deleted...');
    const verifyResponse = await axios.get(`${BASE_URL}/api/v1/users`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (verifyResponse.data.success) {
      const remainingUsers = verifyResponse.data.data || [];
      const userStillExists = remainingUsers.some(user => user.id === userToDelete.id);
      
      if (!userStillExists) {
        console.log('✅ Verification successful: User no longer exists in the system');
      } else {
        console.log('❌ Verification failed: User still exists');
      }
    }
    
  } catch (error) {
    console.error('💥 Test failed with error:', error.response?.data || error.message);
  }
}

testUserDeletion();