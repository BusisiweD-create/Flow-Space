const { Pool } = require('pg');
require('dotenv').config();

console.log('🔍 Finding Users with Similar Email Addresses');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flowspace',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function findSimilarUsers() {
  const client = await pool.connect();
  
  try {
    // Search for users with similar patterns
    const searchPatterns = [
      '%bdhlami%',
      '%@gmail.com',
      'dhlamini331@gmail.com',
      'dhlamininaomi1@gmail.com'
    ];
    
    console.log('\n📋 Searching for users...');
    
    for (const pattern of searchPatterns) {
      const result = await client.query(
        'SELECT id, email, name, role, created_at, is_active FROM users WHERE email LIKE $1 ORDER BY created_at DESC',
        [pattern]
      );
      
      if (result.rows.length > 0) {
        console.log(`\n🎯 Found users matching "${pattern}":`);
        result.rows.forEach((user, index) => {
          console.log(`   ${index + 1}. ID: ${user.id}`);
          console.log(`      Email: ${user.email}`);
          console.log(`      Name: ${user.name}`);
          console.log(`      Role: ${user.role}`);
          console.log(`      Active: ${user.is_active}`);
          console.log(`      Created: ${user.created_at}`);
        });
      }
    }
    
    // Show all users for reference
    console.log('\n📋 All users in database:');
    const allUsers = await client.query(
      'SELECT id, email, name, role, created_at, is_active FROM users ORDER BY created_at DESC'
    );
    
    if (allUsers.rows.length === 0) {
      console.log('   No users found in database');
    } else {
      allUsers.rows.forEach((user, index) => {
        console.log(`   ${index + 1}. ${user.email} (${user.name}) - ${user.role}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

findSimilarUsers().catch(console.error);
