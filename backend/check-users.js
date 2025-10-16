const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flowspace',
  password: 'postgres',
  port: 5432,
});

async function checkUsers() {
  try {
    const result = await pool.query('SELECT id, email, first_name, last_name, is_active FROM users ORDER BY created_at DESC LIMIT 5');
    console.log('📋 Users in database:');
    result.rows.forEach((user, index) => {
      console.log(`${index + 1}. Email: ${user.email}`);
      console.log(`   Name: ${user.first_name} ${user.last_name}`);
      console.log(`   Active: ${user.is_active}`);
      console.log(`   ID: ${user.id}`);
      console.log('---');
    });
    await pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    await pool.end();
  }
}

checkUsers();
