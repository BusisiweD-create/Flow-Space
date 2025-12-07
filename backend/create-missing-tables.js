const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

async function createMissingTables() {
  try {
    console.log('🔧 Creating missing database tables...');
    
    // Create projects table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS projects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'active',
        created_by UUID REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Created projects table');

    // Create sprints table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sprints (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        start_date DATE,
        end_date DATE,
        status VARCHAR(50) DEFAULT 'planned',
        created_by UUID REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Created sprints table');

    // Create tickets table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tickets (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title VARCHAR(255) NOT NULL,
        description TEXT,
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
        status VARCHAR(50) DEFAULT 'open',
        priority VARCHAR(20) DEFAULT 'medium',
        assignee_id UUID REFERENCES users(id),
        created_by UUID REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Created tickets table');

    // Create repository_files table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS repository_files (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        filename VARCHAR(255) NOT NULL,
        original_filename VARCHAR(255) NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER,
        mime_type VARCHAR(100),
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        uploaded_by UUID REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Created repository_files table');

    // Create approval_requests table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS approval_requests (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'pending',
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        requested_by UUID REFERENCES users(id),
        approved_by UUID REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Created approval_requests table');

    // Create notifications table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        message TEXT,
        type VARCHAR(50) DEFAULT 'info',
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Created notifications table');

    // Create some sample data
    console.log('🌱 Creating sample data...');
    
    // Create a sample project
    const projectResult = await pool.query(`
      INSERT INTO projects (name, description, created_by) 
      VALUES ($1, $2, $3) 
      RETURNING id
    `, ['Sample Project', 'A sample project for testing', '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf']);
    
    const projectId = projectResult.rows[0].id;
    console.log('✅ Created sample project');

    // Create a sample sprint
    await pool.query(`
      INSERT INTO sprints (name, description, project_id, created_by) 
      VALUES ($1, $2, $3, $4)
    `, ['Sprint 1', 'First sprint for the sample project', projectId, '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf']);
    console.log('✅ Created sample sprint');

    // Create a sample ticket
    await pool.query(`
      INSERT INTO tickets (title, description, project_id, created_by) 
      VALUES ($1, $2, $3, $4)
    `, ['Sample Ticket', 'A sample ticket for testing', projectId, '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf']);
    console.log('✅ Created sample ticket');

    console.log('🎉 All tables created successfully!');
    
  } catch (error) {
    console.error('❌ Error creating tables:', error);
  } finally {
    await pool.end();
  }
}

createMissingTables();
