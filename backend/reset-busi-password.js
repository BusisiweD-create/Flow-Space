const { Pool } = require('pg');
const bcrypt = require('bcrypt');

async function resetBusiPassword() {
  console.log('🔧 Resetting password for busisiwe.dhlamini@khonology.com...');
  
  const config = {
    user: 'postgres',
    host: 'localhost',
    database: 'flow_space',
    password: 'postgres',
    port: 5432,
  };
  
  const pool = new Pool(config);
  
  try {
    const client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database');
    
    // Hash new password
    const hashedPassword = await bcrypt.hash('password', 10);
    
    // Update user password
    const result = await client.query(`
      UPDATE users 
      SET hashed_password = $1
      WHERE email = 'busisiwe.dhlamini@khonology.com'
      RETURNING id, email, first_name, last_name, role
    `, [hashedPassword]);
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('✅ Password reset successfully!');
      console.log(`   - ID: ${user.id}`);
      console.log(`   - Email: ${user.email}`);
      console.log(`   - Name: ${user.first_name} ${user.last_name}`);
      console.log(`   - Role: ${user.role}`);
      console.log('');
      console.log('🔐 New login credentials:');
      console.log('   Email: busisiwe.dhlamini@khonology.com');
      console.log('   Password: password');
    } else {
      console.log('❌ User not found');
    }
    
    await client.release();
    
  } catch (error) {
    console.error('❌ Error resetting password:', error.message);
  } finally {
    await pool.end();
  }
}

resetBusiPassword();
