const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres',
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function checkUsers() {
  try {
    console.log('📊 Checking users in database...');
    
    const result = await pool.query('SELECT email, name, role, created_at FROM users ORDER BY created_at DESC LIMIT 10');
    
    if (result.rows.length > 0) {
      console.log('👥 Current users in database:');
      result.rows.forEach((user, index) => {
        console.log(`${index + 1}. Email: ${user.email}`);
        console.log(`   Name: ${user.name}`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Created: ${user.created_at}`);
        console.log('');
      });
    } else {
      console.log('ℹ️  No users found in database');
    }
    
  } catch (error) {
    console.error('❌ Error checking users:', error.message);
  } finally {
    await pool.end();
  }
}

checkUsers();
