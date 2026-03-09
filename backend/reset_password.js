const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres'
});

async function resetPassword() {
  try {
    console.log('🔧 Resetting password for Thabang.Nkabinde@khonology.com...');
    
    // Hash the correct password
    const correctPassword = 'Admin123!';
    const hashedPassword = await bcrypt.hash(correctPassword, 10);
    
    console.log('New password hash:', hashedPassword);
    
    // Update the user's password
    const result = await pool.query(
      'UPDATE users SET hashed_password = $1 WHERE email = $2 RETURNING id, email',
      [hashedPassword, 'Thabang.Nkabinde@khonology.com']
    );
    
    if (result.rows.length === 0) {
      console.log('❌ User not found in database');
      return;
    }
    
    const user = result.rows[0];
    console.log('✅ Password updated successfully for:', user.email);
    console.log('User ID:', user.id);
    console.log('New password: Admin123!');
    
    // Verify the new password works
    const verifyResult = await pool.query(
      'SELECT hashed_password FROM users WHERE email = $1',
      ['Thabang.Nkabinde@khonology.com']
    );
    
    const newStoredHash = verifyResult.rows[0].hashed_password;
    const passwordMatches = await bcrypt.compare(correctPassword, newStoredHash);
    
    console.log('✅ Password verification test:', passwordMatches ? 'PASSED' : 'FAILED');
    
    if (!passwordMatches) {
      console.log('❌ Critical error: New password hash verification failed!');
    }
    
  } catch (error) {
    console.error('❌ Error resetting password:', error);
  } finally {
    await pool.end();
  }
}

resetPassword();