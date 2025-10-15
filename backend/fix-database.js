const { Pool } = require('pg');

const config = {
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
};

async function dropAndRecreate() {
  const pool = new Pool(config);
  const client = await pool.connect();
  
  try {
    console.log('🚀 Dropping and recreating users table...');
    
    // Drop existing table
    await client.query('DROP TABLE IF EXISTS users CASCADE');
    console.log('✅ Dropped existing users table');
    
    // Recreate with correct schema that matches Node.js backend expectations
    await client.query(`
      CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        hashed_password VARCHAR(255) NOT NULL,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        company VARCHAR(100),
        role VARCHAR(50) DEFAULT 'user',
        is_active BOOLEAN DEFAULT true,
        is_verified BOOLEAN DEFAULT false,
        verification_token VARCHAR(255),
        reset_token VARCHAR(255),
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Created users table with correct schema');
    
    // Create admin user
    const bcrypt = require('bcrypt');
    const hashedPassword = await bcrypt.hash('password', 10);
    
    await client.query(`
      INSERT INTO users (email, hashed_password, first_name, last_name, role, is_active)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, ['admin@flowspace.com', hashedPassword, 'Admin', 'User', 'systemAdmin', true]);
    
    console.log('✅ Admin user created');
    console.log('📧 Email: admin@flowspace.com');
    console.log('🔑 Password: password');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    client.release();
    pool.end();
  }
}

dropAndRecreate();