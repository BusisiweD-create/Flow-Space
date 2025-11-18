const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres',
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function clearAllUsers() {
  try {
    console.log('🗑️  Clearing all users from database...');
    
    // Delete all users
    const result = await pool.query('DELETE FROM users');
    console.log(`✅ Deleted ${result.rowCount} users`);
    
    // Also clear any related data
    await pool.query('DELETE FROM profiles');
    console.log('✅ Cleared related profile data');
    
    console.log('🎉 Database cleared! You can now register with any email.');
    
  } catch (error) {
    console.error('❌ Error clearing users:', error.message);
  } finally {
    await pool.end();
  }
}

clearAllUsers();
