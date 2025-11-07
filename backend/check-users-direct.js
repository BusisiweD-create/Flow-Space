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
    const result = await pool.query('SELECT * FROM users LIMIT 10');
    console.log('Users found:', result.rows.length);
    result.rows.forEach((user, index) => {
      console.log(`${index + 1}. Email: ${user.email}, Role: ${user.role}`);
    });
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkUsers();