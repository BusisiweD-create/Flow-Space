const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432
});

async function checkAdminUser() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT id, email, first_name, last_name, role FROM users WHERE email = $1', ['admin@flowspace.com']);
    
    if (result.rows.length > 0) {
      console.log('Admin user already exists:');
      console.log(result.rows[0]);
    } else {
      console.log('Admin user does not exist');
    }
    
    await client.release();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkAdminUser();