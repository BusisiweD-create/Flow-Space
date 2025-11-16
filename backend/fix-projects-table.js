const { Pool } = require('pg');

// Database connection configuration
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres',
});

async function fixProjectsTable() {
  const client = await pool.connect();
  
  try {
    console.log('🔧 Fixing projects table structure...');
    
    // Drop the existing projects table if it exists
    await client.query('DROP TABLE IF EXISTS projects CASCADE');
    console.log('✅ Dropped existing projects table');
    
    // Create the correct projects table structure
    await client.query(`
      CREATE TABLE projects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        key VARCHAR(50) UNIQUE NOT NULL,
        description TEXT,
        project_type VARCHAR(50) DEFAULT 'software',
        created_by UUID,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('✅ Created projects table with correct structure');
    
    // Verify the table was created successfully
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'projects'
      ORDER BY ordinal_position;
    `);
    
    console.log('📊 Projects table structure:');
    result.rows.forEach(row => console.log(`  - ${row.column_name} (${row.data_type}, ${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`));
    
  } catch (error) {
    console.error('❌ Error fixing projects table:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

fixProjectsTable();