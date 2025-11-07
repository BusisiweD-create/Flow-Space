const { Pool } = require('pg');
const dbConfig = require('./database-config');

async function checkDatabase() {
  console.log('🔍 Checking database structure...');
  
  const pool = new Pool({
    ...dbConfig,
    database: 'flow_space'
  });
  
  try {
    const client = await pool.connect();
    
    // Check what tables exist
    console.log('\n📊 Existing tables:');
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    
    tablesResult.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });
    
    // Check users table structure
    console.log('\n👤 Users table columns:');
    const usersColumns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    
    usersColumns.rows.forEach(row => {
      console.log(`   - ${row.column_name} (${row.data_type}, nullable: ${row.is_nullable})`);
    });
    
    // Check if there are any users
    console.log('\n👥 Existing users:');
    const usersResult = await client.query('SELECT id, email, name, role FROM users');
    
    if (usersResult.rows.length === 0) {
      console.log('   No users found in the database');
    } else {
      usersResult.rows.forEach(user => {
        console.log(`   - ${user.email} (${user.name}, ${user.role})`);
      });
    }
    
    await client.release();
    
  } catch (error) {
    console.error('❌ Error checking database:', error.message);
  } finally {
    await pool.end();
  }
}

checkDatabase();