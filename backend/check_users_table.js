const { Pool } = require('pg');
const pool = new Pool(require('./database-config.js'));

async function checkUsersTable() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    
    console.log('Users table columns:');
    result.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
    pool.end();
  } catch (error) {
    console.error('Error checking users table:', error.message);
    pool.end();
  }
}

checkUsersTable();