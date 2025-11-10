const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432
});

async function checkAdminRole() {
  try {
    const result = await pool.query(
      'SELECT id, email, role FROM users WHERE email = $1',
      ['admin@flowspace.com']
    );
    console.log('Admin user details:', result.rows[0]);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await pool.end();
  }
}

checkAdminRole();