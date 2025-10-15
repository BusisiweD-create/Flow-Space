const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const dbConfig = require('./database-config');

async function createTestUsers() {
  console.log('👤 Creating test users...');
  
  const pool = new Pool({
    ...dbConfig,
    database: 'flow_space'
  });
  
  try {
    const client = await pool.connect();
    
    // Create test admin user
    console.log('📝 Creating admin user...');
    const adminPassword = await bcrypt.hash('admin123', 10);
    await client.query(`
      INSERT INTO users (email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        'admin@flowspace.com', 
        $1,
        'Admin',
        'User',
        'admin',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [adminPassword]);
    
    // Create test client reviewer user
    console.log('📝 Creating client reviewer user...');
    const clientPassword = await bcrypt.hash('password123', 10);
    await client.query(`
      INSERT INTO users (email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        'clientreviewer@example.com', 
        $1,
        'Client',
        'Reviewer',
        'clientReviewer',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [clientPassword]);
    
    // Create test team member user
    console.log('📝 Creating team member user...');
    const teamPassword = await bcrypt.hash('password123', 10);
    await client.query(`
      INSERT INTO users (email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        'teammember@example.com', 
        $1,
        'Team',
        'Member',
        'teamMember',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [teamPassword]);
    
    console.log('✅ Test users created successfully!');
    console.log('\n📋 Test user credentials:');
    console.log('   Admin: admin@flowspace.com / admin123');
    console.log('   Client Reviewer: clientreviewer@example.com / password123');
    console.log('   Team Member: teammember@example.com / password123');
    
    await client.release();
    
  } catch (error) {
    console.error('❌ Error creating test users:', error.message);
  } finally {
    await pool.end();
  }
}

createTestUsers();