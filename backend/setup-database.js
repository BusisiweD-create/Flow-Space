const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'postgres',
  password: 'postgres',
  port: 5432,
});

async function setupDatabase() {
  try {
    // Check if flowspace database exists
    const result = await pool.query("SELECT 1 FROM pg_database WHERE datname = 'flowspace'");
    
    if (result.rows.length === 0) {
      console.log('📋 Creating flowspace database...');
      await pool.query('CREATE DATABASE flowspace');
      console.log('✅ Database created successfully!');
    } else {
      console.log('✅ flowspace database already exists');
    }
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    await pool.end();
  }
}

setupDatabase();