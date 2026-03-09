const { Pool } = require('pg');

// Database configuration
const config = {
  user: 'postgres',
  host: 'localhost',
  database: 'postgres',
  password: 'postgres',
  port: 5432,
};

async function quickSetup() {
  let client;
  
  try {
    console.log('🚀 Quick database setup...');
    
    const pool = new Pool(config);
    client = await pool.connect();
    console.log('✅ Connected to PostgreSQL');
    
    // Create database
    try {
      await client.query('CREATE DATABASE flow_space');
      console.log('✅ Database created');
    } catch (error) {
      if (error.code === '42P04') {
        console.log('✅ Database already exists');
      }
    }
    
    await client.release();
    
    // Connect to flow_space
    const flowConfig = {...config, database: 'flow_space'};
    const flowPool = new Pool(flowConfig);
    client = await flowPool.connect();
    
    // Create users table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        hashed_password VARCHAR(255) NOT NULL,
        first_name VARCHAR(255) NOT NULL,
        last_name VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'teamMember',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Create admin user
    const bcrypt = require('bcrypt');
    const { v4: uuidv4 } = require('uuid');
    const hashedPassword = await bcrypt.hash('password', 10);
    const adminId = uuidv4();
    
    await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (email) DO UPDATE SET
        hashed_password = EXCLUDED.hashed_password,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        role = EXCLUDED.role
    `, [adminId, 'admin@flowspace.com', hashedPassword, 'Admin', 'User', 'systemAdmin', true]);
    
    console.log('✅ Admin user created');
    console.log('📧 Email: admin@flowspace.com');
    console.log('🔑 Password: password');
    console.log('✅ Setup complete!');
    
  } catch (error) {
    console.error('❌ Setup failed:', error.message);
  } finally {
    if (client) await client.release();
  }
}

if (require.main === module) {
  quickSetup();
}