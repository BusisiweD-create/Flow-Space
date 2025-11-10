const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres'
});

async function testConnection() {
  try {
    const client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database');
    
    // Check if projects table exists
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_name = 'projects'
    `);
    
    if (result.rows.length > 0) {
      console.log('✅ Projects table exists');
      
      // Check the structure of the projects table
      const structure = await client.query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'projects'
        ORDER BY ordinal_position;
      `);
      
      console.log('📊 Projects table structure:');
      structure.rows.forEach(row => {
        console.log(`  - ${row.column_name} (${row.data_type}, ${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
      });
    } else {
      console.log('❌ Projects table does not exist');
    }
    
    client.release();
  } catch (error) {
    console.error('❌ Database connection error:', error.message);
  } finally {
    await pool.end();
  }
}

testConnection();