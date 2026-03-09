const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres',
});

async function checkUsers() {
  try {
    console.log('🔍 Checking users in database...');
    
    const result = await pool.query(`
      SELECT id, email, first_name, last_name, hashed_password, role, is_active, created_at 
      FROM users 
      ORDER BY created_at DESC
    `);
    
    console.log(`📊 Found ${result.rows.length} users:`);
    console.log('='.repeat(80));
    
    result.rows.forEach((user, index) => {
      const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'Not set';
      console.log(`${index + 1}. ${user.email} (${fullName})`);
      console.log(`   ID: ${user.id}`);
      console.log(`   Role: ${user.role}, Active: ${user.is_active}`);
      console.log(`   Created: ${user.created_at}`);
      console.log(`   Password hash: ${user.hashed_password ? 'Set' : 'Not set'}`);
      console.log('─'.repeat(80));
    });
    
  } catch (error) {
    console.error('❌ Error checking users:', error.message);
  } finally {
    await pool.end();
  }
}

checkUsers();