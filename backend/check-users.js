const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'flow_space',
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 5432,
});

async function checkUsers() {
  try {
    const result = await pool.query('SELECT id, name, email FROM users LIMIT 5');
    console.log('Users in database:');
    result.rows.forEach(user => {
      console.log(`ID: ${user.id}, Name: ${user.name}, Email: ${user.email}`);
    });
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkUsers();