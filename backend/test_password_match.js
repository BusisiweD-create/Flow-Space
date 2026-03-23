const bcrypt = require('bcrypt');

async function testPasswordMatch() {
  try {
    const storedHash = '$2b$10$fOiRBnMcGWNzUDi4jFA9YOCzz5U4xs7Goj..zkTX/XK1cUQI7.u62';
    const testPassword = 'admin123';
    
    console.log('Testing password match...');
    console.log('Stored hash:', storedHash);
    console.log('Test password:', testPassword);
    
    const isMatch = await bcrypt.compare(testPassword, storedHash);
    console.log('Password matches:', isMatch);
    
    // Also test if we can generate the same hash
    const newHash = await bcrypt.hash(testPassword, 10);
    console.log('New hash for comparison:', newHash);
    
  } catch (error) {
    console.error('Error testing password match:', error);
  }
}

testPasswordMatch();