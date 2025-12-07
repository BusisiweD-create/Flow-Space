const { Pool } = require('pg');
const pool = new Pool({ connectionString: 'postgresql://localhost:5432/flow_space' });

async function checkTables() {
  try {
    const client = await pool.connect();
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);
    console.log('📊 Existing tables:');
    result.rows.forEach(row => console.log('  -', row.table_name));
    
    // Check if projects table exists and its structure
    const projectsResult = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'projects'
      ORDER BY ordinal_position;
    `);
    
    if (projectsResult.rows.length > 0) {
      console.log('\n🏗️  Projects table structure:');
      projectsResult.rows.forEach(row => console.log(`  - ${row.column_name} (${row.data_type}, ${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`));
    } else {
      console.log('\n❌ Projects table does not exist');
    }
    
    client.release();
  } catch (error) {
    console.error('Error checking tables:', error.message);
  } finally {
    await pool.end();
  }
}

checkTables();