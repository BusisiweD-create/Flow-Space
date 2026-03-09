
const axios = require('axios');
require('dotenv').config({ path: '../.env' });

async function getAuthToken() {
    try {
        const response = await axios.post('http://localhost:8000/api/v1/auth/login', {
            email: 'admin@example.com', // Replace with valid admin credentials if needed, or use the one we reset
            password: 'Password123!'
        });
        return response.data.token;
    } catch (error) {
        // Try the Thabang user we reset earlier
        try {
             const response = await axios.post('http://localhost:8000/api/v1/auth/login', {
                email: 'Thabang.Nkabinde@khonology.com',
                password: 'Password123!'
            });
            return response.data.token;
        } catch (e) {
            console.error('Login failed:', e.message);
            process.exit(1);
        }
    }
}

module.exports = { getAuthToken };
