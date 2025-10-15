const { Pool } = require('pg');
const bcrypt = require('bcrypt');

async function createAdminUser() {
  console.log('🔧 Creating admin user...');
  
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
    
    // Check if users table exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
      )
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.log('❌ Users table does not exist. Please run database setup first.');
      return;
    }
    
    // Hash password for admin user
    const hashedPassword = await bcrypt.hash('password', 10);
    
    // Create admin user
    const result = await client.query(`
      INSERT INTO users (email, password_hash, name, role, is_active)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (email) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        name = EXCLUDED.name,
        role = EXCLUDED.role,
        is_active = EXCLUDED.is_active
      RETURNING id, email, name, role
    `, ['admin@flowspace.com', hashedPassword, 'Admin User', 'systemAdmin', true]);
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('✅ Admin user created/updated successfully!');
      console.log(`   - ID: ${user.id}`);
      console.log(`   - Email: ${user.email}`);
      console.log(`   - Name: ${user.name}`);
      console.log(`   - Role: ${user.role}`);
      console.log('');
      console.log('🔐 Login credentials:');
      console.log('   Email: admin@flowspace.com');
      console.log('   Password: password');
    } else {
      console.log('⚠️  Admin user already exists and was updated');
    }
    
    await client.release();
    
  } catch (error) {
    console.error('❌ Error creating admin user:', error.message);
    console.log('');
    console.log('🔧 Troubleshooting:');
    console.log('   1. Make sure PostgreSQL is running');
    console.log('   2. Check if flow_space database exists');
    console.log('   3. Verify database credentials in backend/database-config.js');
    console.log('   4. Run database setup: node backend/setup-database.js');
  } finally {
    await pool.end();
  }
}

// Run if this file is executed directly
if (require.main === module) {
  createAdminUser();
}

module.exports = { createAdminUser };