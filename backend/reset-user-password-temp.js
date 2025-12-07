// Reset password for mabotsaboitumelo5@gmail.com
require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'flowspace',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

async function resetPassword(email, newPassword) {
  try {
    // Hash the new password
    const passwordHash = await bcrypt.hash(newPassword, 10);
    
    // Update the user's password
    const result = await pool.query(
      'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING email, name',
      [passwordHash, email]
    );
    
    if (result.rows.length === 0) {
      console.log(`❌ User not found: ${email}`);
      return;
    }
    
    console.log(`✅ Password reset successfully for ${result.rows[0].email} (${result.rows[0].name})`);
    console.log(`\n📝 New login credentials:`);
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${newPassword}`);
    console.log(`\n💡 Please use these credentials to log in.`);
    
  } catch (error) {
    console.error('Error resetting password:', error);
  } finally {
    await pool.end();
  }
}

const email = process.argv[2] || 'mabotsaboitumelo5@gmail.com';
const newPassword = process.argv[3] || 'password123'; // Default password

console.log(`\n🔐 Resetting password for: ${email}`);
console.log(`📝 New password will be: ${newPassword}\n`);

resetPassword(email, newPassword);

