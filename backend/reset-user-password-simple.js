const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

async function resetUserPassword() {
  try {
    console.log('🔧 Resetting password for user...');
    
    // Reset password for mabotsaboitumelo5@gmail.com
    const email = 'mabotsaboitumelo5@gmail.com';
    const newPassword = 'password123';
    
    // For testing, let's set a simple password that matches what the server expects
    // The server uses bcryptjs, so we need to hash it properly
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update the user's password
    const result = await pool.query(
      'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING email, name',
      [hashedPassword, email]
    );
    
    if (result.rows.length > 0) {
      console.log(`✅ Password reset successful for: ${result.rows[0].email}`);
      console.log(`   Name: ${result.rows[0].name}`);
      console.log(`   New Password: ${newPassword}`);
      console.log('\n📝 You can now log in with:');
      console.log(`   Email: ${email}`);
      console.log(`   Password: ${newPassword}`);
    } else {
      console.log('❌ User not found');
    }
    
  } catch (error) {
    console.error('❌ Error resetting password:', error);
  } finally {
    await pool.end();
  }
}

resetUserPassword();
