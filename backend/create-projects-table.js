const { Pool } = require('pg');

// Database connection configuration
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres', // Default PostgreSQL password
});

async function createProjectsTable() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Creating projects table if it doesn\'t exist...');
    
    // Create projects table
    await client.query(`
      CREATE TABLE IF NOT EXISTS projects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        owner_id UUID,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('✅ Projects table created or already exists');
    
    // Check if table was created successfully
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_name = 'projects'
    `);
    
    if (result.rows.length > 0) {
      console.log('✅ Projects table verified');
    } else {
      console.log('❌ Projects table creation failed');
    }
    
  } catch (error) {
    console.error('❌ Error creating projects table:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

createProjectsTable();