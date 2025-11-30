const pool = require('./db');

async function clearUser() {
  try {
    console.log('🗑️  Clearing user from database...');
    
    // Delete the specific user
    const result = await pool.query('DELETE FROM users WHERE email = $1', ['dhlaminibusisiwe30@gmail.com']);
    
    if (result.rowCount > 0) {
      console.log('✅ User deleted successfully');
    } else {
      console.log('ℹ️  User not found (may have been already deleted)');
    }
    
    // Also clear any related data
    await pool.query('DELETE FROM profiles WHERE email = $1', ['dhlaminibusisiwe30@gmail.com']);
    console.log('✅ Related profile data cleared');
    
  } catch (error) {
    console.error('❌ Error clearing user:', error.message);
  } finally {
    await pool.end();
  }
}

clearUser();
