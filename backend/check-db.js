const { Pool } = require('pg');
const dbConfig = require('./database-config');

async function checkDatabase() {
  const pool = new Pool(dbConfig);
  let client;
  
  try {
    client = await pool.connect();
    
    // Check users table columns
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    
    console.log('Users table columns:');
    result.rows.forEach(row => {
      console.log(`  - ${row.column_name} (${row.data_type}, ${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
    // Check if admin user exists
    const adminResult = await client.query('SELECT email, first_name, last_name, role FROM users WHERE email = $1', ['admin@flowspace.com']);
    console.log('\nAdmin user:');
    if (adminResult.rows.length > 0) {
      console.log(`  - Email: ${adminResult.rows[0].email}`);
      console.log(`  - Name: ${adminResult.rows[0].first_name} ${adminResult.rows[0].last_name}`);
      console.log(`  - Role: ${adminResult.rows[0].role}`);
    } else {
      console.log('  - Not found');
    }
    
  } catch (error) {
    console.error('Error checking database:', error.message);
  } finally {
    if (client) await client.release();
    await pool.end();
  }
}

checkDatabase();