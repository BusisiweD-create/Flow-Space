const { Pool } = require('pg');
const bcrypt = require('bcrypt');

async function createGessicaUser() {
  console.log('🔧 Creating Gessica Cumbane user...');
  
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
    
    // Hash password for Gessica user
    const hashedPassword = await bcrypt.hash('password123', 10);
    
    // Create Gessica Cumbane as client reviewer
    const gessicaResult = await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active)
      VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO UPDATE SET
        hashed_password = EXCLUDED.hashed_password,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        role = EXCLUDED.role,
        is_active = EXCLUDED.is_active
      RETURNING id, email, first_name, last_name, role
    `, ['gessica.cumbane@example.com', hashedPassword, 'Gessica', 'Cumbane', 'clientReviewer', true]);
    
    if (gessicaResult.rows.length > 0) {
      const user = gessicaResult.rows[0];
      const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim();
      console.log('✅ Gessica Cumbane user created/updated successfully!');
      console.log(`   - ID: ${user.id}`);
      console.log(`   - Email: ${user.email}`);
      console.log(`   - Name: ${fullName}`);
      console.log(`   - Role: ${user.role}`);
    } else {
      console.log('⚠️  Gessica Cumbane user already exists and was updated');
    }
    
    console.log('');
    console.log('🔐 Login credentials:');
    console.log('   Email: gessica.cumbane@example.com');
    console.log('   Password: password123');
    console.log('   Role: clientReviewer');
    
    await client.release();
    
  } catch (error) {
    console.error('❌ Error creating Gessica user:', error.message);
    console.log('');
    console.log('🔧 Troubleshooting:');
    console.log('   1. Make sure PostgreSQL is running');
    console.log('   2. Check if flow_space database exists');
    console.log('   3. Verify database credentials');
  } finally {
    await pool.end();
  }
}

// Run if this file is executed directly
if (require.main === module) {
  createGessicaUser();
}

module.exports = { createGessicaUser };