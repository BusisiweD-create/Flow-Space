const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const dbConfig = require('./database-config');

async function createAdminUser() {
  const pool = new Pool(dbConfig);
  let client;
  
  try {
    client = await pool.connect();
    
    // Hash the password
    const hashedPassword = await bcrypt.hash('password', 10);
    
    // Create admin user
    const result = await client.query(`
      INSERT INTO users (email, hashed_password, first_name, last_name, role, is_active)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO UPDATE SET
        hashed_password = EXCLUDED.hashed_password,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        role = EXCLUDED.role,
        is_active = EXCLUDED.is_active
      RETURNING id, email, first_name, last_name, role
    `, ['admin@flowspace.com', hashedPassword, 'Admin', 'User', 'systemAdmin', true]);
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('✅ Admin user created/updated:');
      console.log(`   - Email: ${user.email}`);
      console.log(`   - Name: ${user.first_name} ${user.last_name}`);
      console.log(`   - Role: ${user.role}`);
      console.log('   - Password: password');
    } else {
      console.log('❌ Failed to create admin user');
    }
    
  } catch (error) {
    console.error('Error creating admin user:', error.message);
  } finally {
    if (client) await client.release();
    await pool.end();
  }
}

createAdminUser();