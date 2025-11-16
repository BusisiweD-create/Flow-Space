const bcrypt = require('bcrypt');

async function testPasswordVerification() {
  try {
    // This is the hash from the database for Thabang.Nkabinde@khonology.com
    const storedHash = '$2b$10$cByytPj7pvHXS9/UqP1i8O9AFNzrb0iolKDGZi7g6dB1sXXxC4PUq';
    const testPassword = 'Admin123!';
    
    console.log('🔍 Testing password verification...');
    console.log('Stored hash:', storedHash);
    console.log('Test password:', testPassword);
    
    // Test if the password matches the hash
    const isMatch = await bcrypt.compare(testPassword, storedHash);
    console.log('Password matches:', isMatch);
    
    // Also test if we can generate the same hash
    const newHash = await bcrypt.hash(testPassword, 10);
    console.log('New hash for comparison:', newHash);
    
    // Test if the new hash matches the stored hash
    const newHashMatch = await bcrypt.compare(testPassword, newHash);
    console.log('New hash matches password:', newHashMatch);
    
    // Test if the stored hash matches itself (should be true)
    const hashSelfMatch = await bcrypt.compare('Admin123!', storedHash);
    console.log('Stored hash matches correct password:', hashSelfMatch);
    
  } catch (error) {
    console.error('❌ Error testing password verification:', error);
  }
}

testPasswordVerification();