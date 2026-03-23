const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432
});

async function checkUsersTable() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT column_name, data_type FROM information_schema.columns WHERE table_name = \'users\' ORDER BY ordinal_position');
    console.log('Users table columns:');
    result.rows.forEach(row => {
      console.log(`  ${row.column_name} (${row.data_type})`);
    });
    await client.release();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkUsersTable();