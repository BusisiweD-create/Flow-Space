const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
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
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        $1,
        'admin@flowspace.com', 
        $2,
        'Admin',
        'User',
        'admin',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [uuidv4(), adminPassword]);
    
    // Create test client reviewer user
    console.log('📝 Creating client reviewer user...');
    const clientPassword = await bcrypt.hash('password123', 10);
    await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        $1,
        'clientreviewer@example.com', 
        $2,
        'Client',
        'Reviewer',
        'clientReviewer',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [uuidv4(), clientPassword]);
    
    // Create test team member user
    console.log('📝 Creating team member user...');
    const teamPassword = await bcrypt.hash('password123', 10);
    await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        $1,
        'teammember@example.com', 
        $2,
        'Team',
        'Member',
        'teamMember',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [uuidv4(), teamPassword]);

    // Create QA Engineer test user
    const qaPassword = await bcrypt.hash('qa123', 10);
    await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        $1,
        'qaengineer@example.com', 
        $2,
        'QA',
        'Engineer',
        'qaEngineer',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [uuidv4(), qaPassword]);

    // Create Scrum Master test user
    const scrumPassword = await bcrypt.hash('scrum123', 10);
    await client.query(`
      INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active, created_at)
      VALUES (
        $1,
        'scrummaster@example.com', 
        $2,
        'Scrum',
        'Master',
        'scrumMaster',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [uuidv4(), scrumPassword]);
    
    console.log('✅ Test users created successfully!');
    console.log('\n📋 Test user credentials:');
    console.log('   Admin: admin@flowspace.com / admin123');
    console.log('   Client Reviewer: clientreviewer@example.com / password123');
    console.log('   Team Member: teammember@example.com / password123');
    console.log('   QA Engineer: qaengineer@example.com / qa123');
    console.log('   Scrum Master: scrummaster@example.com / scrum123');
    
    await client.release();
    
  } catch (error) {
    console.error('❌ Error creating test users:', error.message);
  } finally {
    await pool.end();
  }
}

createTestUsers();