const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

async function resetPasswords() {
  try {
    console.log('🔧 Resetting passwords for users...');
    
    const bcrypt = require('bcryptjs');
    
    // Users to reset with their new passwords
    const users = [
      { email: 'dhlamini331@gmail.com', newPassword: 'Password@1' },
      { email: 'bdhlamini883@gmail.com', newPassword: 'Password@1' },
      { email: 'busisiwe.dhlamini@khonology.com', newPassword: 'Password@1' }
    ];
    
    for (const user of users) {
      console.log(`\n🔄 Processing: ${user.email}`);
      
      // Hash the new password
      const hashedPassword = await bcrypt.hash(user.newPassword, 10);
      
      // Update the user's password
      const result = await pool.query(
        'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING email, name',
        [hashedPassword, user.email]
      );
      
      if (result.rows.length > 0) {
        console.log(`✅ Password reset successful for: ${result.rows[0].email}`);
        console.log(`   Name: ${result.rows[0].name}`);
        console.log(`   New Password: ${user.newPassword}`);
      } else {
        console.log(`❌ User not found: ${user.email}`);
      }
    }
    
    console.log('\n📝 Summary - You can now log in with:');
    console.log('   Email: dhlamini331@gmail.com');
    console.log('   Password: Password@1');
    console.log('   ---');
    console.log('   Email: bdhlamini883@gmail.com');
    console.log('   Password: Password@1');
    console.log('   ---');
    console.log('   Email: busisiwe.dhlamini@khonology.com');
    console.log('   Password: Password@1');
    
  } catch (error) {
    console.error('❌ Error resetting passwords:', error);
  } finally {
    await pool.end();
  }
}

resetPasswords();
