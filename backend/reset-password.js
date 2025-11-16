// Reset password for original user
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function resetPassword() {
  try {
    console.log('🔐 Resetting password for your original account...\n');
    
    const email = 'test@example.com';
    const newPassword = 'password123'; // You can change this to whatever you want
    
    console.log(`👤 User: ${email}`);
    console.log(`🔑 New password: ${newPassword}`);
    console.log('');
    
    // Hash the new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update the password
    const result = await pool.query(`
      UPDATE users 
      SET password_hash = $1, updated_at = NOW()
      WHERE email = $2
      RETURNING id, email, name, role
    `, [hashedPassword, email]);
    
    if (result.rows.length === 0) {
      console.log('❌ User not found');
      return;
    }
    
    const user = result.rows[0];
    console.log('✅ Password reset successfully!');
    console.log(`   👤 Name: ${user.name}`);
    console.log(`   📧 Email: ${user.email}`);
    console.log(`   🎭 Role: ${user.role}`);
    
    console.log('\n🎉 You can now login with:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${newPassword}`);
    
    console.log('\n💡 You can change this password later through your app or by running this script again');
    
  } catch (error) {
    console.error('❌ Error resetting password:', error.message);
  } finally {
    await pool.end();
  }
}

resetPassword();
