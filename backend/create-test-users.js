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
      INSERT INTO users (email, password_hash, name, role, is_active, created_at)
      VALUES (
        'admin@flowspace.com', 
        $1,
        'Admin User',
        'systemAdmin',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [adminPassword]);
    
    // Create test client reviewer user
    console.log('📝 Creating client reviewer user...');
    const clientPassword = await bcrypt.hash('password123', 10);
    await client.query(`
      INSERT INTO users (email, password_hash, name, role, is_active, created_at)
      VALUES (
        'clientreviewer@example.com', 
        $1,
        'Client Reviewer',
        'clientReviewer',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [clientPassword]);
    
    // Create test team member user
    console.log('📝 Creating team member user...');
    const teamPassword = await bcrypt.hash('password123', 10);
    await client.query(`
      INSERT INTO users (email, password_hash, name, role, is_active, created_at)
      VALUES (
        'teammember@example.com', 
        $1,
        'Team Member',
        'teamMember',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [teamPassword]);

    // Create QA Engineer test user
    const qaPassword = await bcrypt.hash('qa123', 10);
    await client.query(`
      INSERT INTO users (email, password_hash, name, role, is_active, created_at)
      VALUES (
        'qaengineer@example.com', 
        $1,
        'QA Engineer',
        'qaEngineer',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [qaPassword]);

    // Create Scrum Master test user
    const scrumPassword = await bcrypt.hash('scrum123', 10);
    await client.query(`
      INSERT INTO users (email, password_hash, name, role, is_active, created_at)
      VALUES (
        'scrummaster@example.com', 
        $1,
        'Scrum Master',
        'scrumMaster',
        true,
        NOW()
      ) ON CONFLICT (email) DO NOTHING
    `, [scrumPassword]);
    
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