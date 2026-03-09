const { Pool } = require('pg');
const bcrypt = require('bcrypt');

async function createAdminUser() {
  console.log('🔧 Creating admin users...');
  
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
    
    // Enable UUID extension if not already enabled
    await client.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
    
    // Hash password for admin user
    const hashedPassword = await bcrypt.hash('password', 10);
    
    // Create admin user
    const adminResult = await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active)
      VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO UPDATE SET
        hashed_password = EXCLUDED.hashed_password,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        role = EXCLUDED.role,
        is_active = EXCLUDED.is_active
      RETURNING id, email, first_name, last_name, role
    `, ['admin@flowspace.com', hashedPassword, 'Admin', 'User', 'admin', true]);
    
    if (adminResult.rows.length > 0) {
      const user = adminResult.rows[0];
      console.log('✅ Admin user created/updated successfully!');
      console.log(`   - ID: ${user.id}`);
      console.log(`   - Email: ${user.email}`);
      console.log(`   - Name: ${user.first_name} ${user.last_name}`);
      console.log(`   - Role: ${user.role}`);
    } else {
      console.log('⚠️  Admin user already exists and was updated');
    }
    
    // Create system admin user
    const systemAdminResult = await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active)
      VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO UPDATE SET
        hashed_password = EXCLUDED.hashed_password,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        role = EXCLUDED.role,
        is_active = EXCLUDED.is_active
      RETURNING id, email, first_name, last_name, role
    `, ['systemadmin@flowspace.com', hashedPassword, 'System', 'Admin', 'system_admin', true]);
    
    if (systemAdminResult.rows.length > 0) {
      const user = systemAdminResult.rows[0];
      console.log('✅ System Admin user created/updated successfully!');
      console.log(`   - ID: ${user.id}`);
      console.log(`   - Email: ${user.email}`);
      console.log(`   - Name: ${user.first_name} ${user.last_name}`);
      console.log(`   - Role: ${user.role}`);
    } else {
      console.log('⚠️  System Admin user already exists and was updated');
    }
    
    console.log('');
    console.log('🔐 Login credentials:');
    console.log('   Admin User (for user management):');
    console.log('     Email: admin@flowspace.com');
    console.log('     Password: password');
    console.log('   System Admin User (for system management):');
    console.log('     Email: systemadmin@flowspace.com');
    console.log('     Password: password');
    
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