
const axios = require('axios');
const { getAuthToken } = require('./auth-helper');

async function checkUsers() {
  try {
    const token = await getAuthToken();
    const response = await axios.get('http://localhost:8000/api/v1/users', {
      headers: { Authorization: `Bearer ${token}` }
    });

    console.log('Response status:', response.status);
    if (response.data.users && response.data.users.length > 0) {
        console.log('First user sample:', JSON.stringify(response.data.users[0], null, 2));
    } else {
        console.log('No users found or unexpected format:', Object.keys(response.data));
    }
  } catch (error) {
    console.error('Error:', error.message);
    if (error.response) {
        console.error('Response data:', error.response.data);
    }
  }
}

checkUsers();
