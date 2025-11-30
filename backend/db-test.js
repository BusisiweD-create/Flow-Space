const pool = require('./db');

async function testConnection() {
  try {
    const result = await pool.query('SELECT NOW() AS current_time');
    console.log('Database connected successfully');
    console.log('Current database time:', result.rows[0].current_time);
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      console.log('Database connectivity check: PostgreSQL is not reachable at', {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
      });
    } else {
      console.error('Database connection failed:', error.message || error);
    }
  } finally {
    await pool.end();
  }
}

testConnection();

