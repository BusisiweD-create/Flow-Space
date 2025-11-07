// Reset passwords for your real user accounts
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

async function resetRealUserPasswords() {
  try {
    console.log('🔐 Setting up passwords for your real user accounts...\n');
    
    const users = [
      { email: 'john@acme.com', name: 'John Doe', password: 'john123' },
      { email: 'jane@acme.com', name: 'Jane Smith', password: 'jane123' }
    ];
    
    for (const user of users) {
      console.log(`🔑 Setting password for ${user.name} (${user.email})`);
      
      // Hash the password
      const hashedPassword = await bcrypt.hash(user.password, 10);
      
      // Update the password
      const result = await pool.query(`
        UPDATE users 
        SET password_hash = $1, updated_at = NOW()
        WHERE email = $2
        RETURNING id, email, name, role
      `, [hashedPassword, user.email]);
      
      if (result.rows.length === 0) {
        console.log(`   ❌ User not found: ${user.email}`);
        continue;
      }
      
      const updatedUser = result.rows[0];
      console.log(`   ✅ Password set successfully!`);
      console.log(`   👤 Name: ${updatedUser.name}`);
      console.log(`   📧 Email: ${updatedUser.email}`);
      console.log(`   🎭 Role: ${updatedUser.role}`);
      console.log(`   🔑 Password: ${user.password}`);
      console.log('');
    }
    
    console.log('🎉 Password setup completed!');
    console.log('\n💡 You can now login with these accounts:');
    console.log('   📧 john@acme.com / Password: john123');
    console.log('   📧 jane@acme.com / Password: jane123');
    console.log('\n🔐 You can change these passwords later through your app');
    
  } catch (error) {
    console.error('❌ Error setting passwords:', error.message);
  } finally {
    await pool.end();
  }
}

resetRealUserPasswords();
