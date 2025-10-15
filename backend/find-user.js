const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function findUser() {
  try {
    const result = await pool.query('SELECT id, email, first_name, last_name, role FROM users WHERE email = $1', ['Tshepo.Madiba@khonology.com']);
    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('User found:');
      console.log('ID:', user.id);
      console.log('Email:', user.email);
      console.log('First Name:', user.first_name);
      console.log('Last Name:', user.last_name);
      console.log('Current Role:', user.role);
    } else {
      console.log('User not found');
    }
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

findUser();