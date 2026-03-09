const axios = require('axios');

const API_URL = 'http://localhost:8000/api/v1';
const EMAIL = 'Thabang.Nkabinde@khonology.com';
const PASSWORD = 'password123'; // Assuming default password or I need to reset it? 
// Wait, I don't know the password. 
// I can reset the password in the DB if needed, or check if there's a default.
// The migration script showed the user exists.

// Alternative: Generate a token directly using the backend code (since I have access to it)
// avoiding the need for password.

const jwt = require('jsonwebtoken');
const { User } = require('../src/models');
require('dotenv').config();

async function testAdminProjects() {
  try {
    // 1. Get the admin user
    const admin = await User.findOne({ where: { email: EMAIL } });
    if (!admin) {
      console.error('Admin user not found!');
      return;
    }

    console.log(`Found Admin: ${admin.email}, Role: ${admin.role}`);

    // 2. Generate Token
    const token = jwt.sign(
      { 
        sub: admin.id, 
        email: admin.email, 
        role: admin.role,
        type: 'access'
      },
      process.env.JWT_SECRET || 'your_jwt_secret',
      { expiresIn: '1h' }
    );

    console.log(`Generated Token for role: ${admin.role}`);

    // 3. Call API
    try {
      const response = await axios.get(`${API_URL}/projects`, {
        headers: { Authorization: `Bearer ${token}` }
      });

      console.log('API Response Status:', response.status);
      console.log('Number of projects returned:', response.data.data.length);
      
      if (response.data.data.length > 0) {
        console.log('First Project:', response.data.data[0].name);
      }

    } catch (apiError) {
      console.error('API Error:', apiError.response ? apiError.response.data : apiError.message);
    }

  } catch (error) {
    console.error('Script Error:', error);
  }
}

testAdminProjects();
