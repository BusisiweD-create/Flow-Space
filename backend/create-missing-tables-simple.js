const { Pool } = require('pg');

async function createMissingTables() {
  console.log('🔧 Creating missing database tables...');
  
  const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'flow_space',
    password: 'postgres',
    port: 5432,
  });
  
  try {
    const client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database');
    
    // Enable UUID extension
    await client.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
    
    // Create projects table
    await client.query(`
      CREATE TABLE IF NOT EXISTS projects (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        client_name VARCHAR(255),
        repository_url VARCHAR(500),
        documentation_url VARCHAR(500),
        start_date DATE,
        end_date DATE,
        status VARCHAR(50) DEFAULT 'active',
        owner_id UUID REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Projects table created');
    
    // Create sprints table with project_id
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprints (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
        start_date DATE,
        end_date DATE,
        committed_points INTEGER DEFAULT 0,
        completed_points INTEGER DEFAULT 0,
        velocity INTEGER DEFAULT 0,
        test_pass_rate DECIMAL(5,2) DEFAULT 0.0,
        code_coverage INTEGER DEFAULT 0,
        defect_count INTEGER DEFAULT 0,
        escaped_defects INTEGER DEFAULT 0,
        defects_closed INTEGER DEFAULT 0,
        carried_over_points INTEGER DEFAULT 0,
        scope_changes TEXT[],
        risks_identified INTEGER DEFAULT 0,
        risks_mitigated INTEGER DEFAULT 0,
        blockers TEXT,
        decisions TEXT,
        status VARCHAR(50) DEFAULT 'planning',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Sprints table created');
    
    // Create sprint_deliverables table
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprint_deliverables (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
        deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
        points INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Sprint deliverables table created');
    
    // Create audit_logs table
    await client.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID REFERENCES users(id),
        action VARCHAR(100) NOT NULL,
        resource_type VARCHAR(50) NOT NULL,
        resource_id UUID,
        details JSONB,
        ip_address INET,
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Audit logs table created');
    
    console.log('');
    console.log('🎉 All missing tables created successfully!');
    console.log('✅ Database is now ready for project management');
    
    await client.release();
    
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
  } finally {
    await pool.end();
  }
}

createMissingTables();
