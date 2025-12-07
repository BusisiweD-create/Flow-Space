const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

async function addSampleData() {
  try {
    console.log('🌱 Adding sample data...');
    
    // Get the project ID we created
    const projectResult = await pool.query('SELECT id FROM projects LIMIT 1');
    if (projectResult.rows.length === 0) {
      console.log('❌ No projects found. Creating a sample project first...');
      
      const newProject = await pool.query(`
        INSERT INTO projects (name, description, created_by) 
        VALUES ($1, $2, $3) 
        RETURNING id
      `, ['Sample Project', 'A sample project for testing', '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf']);
      
      projectId = newProject.rows[0].id;
      console.log('✅ Created sample project');
    } else {
      projectId = projectResult.rows[0].id;
      console.log('✅ Using existing project');
    }

    // Get the sprint ID we created
    const sprintResult = await pool.query('SELECT id FROM sprints LIMIT 1');
    if (sprintResult.rows.length === 0) {
      console.log('❌ No sprints found. Creating a sample sprint...');
      
      const newSprint = await pool.query(`
        INSERT INTO sprints (name, description, project_id, created_by) 
        VALUES ($1, $2, $3, $4)
        RETURNING id
      `, ['Sprint 1', 'First sprint for the sample project', projectId, '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf']);
      
      sprintId = newSprint.rows[0].id;
      console.log('✅ Created sample sprint');
    } else {
      sprintId = sprintResult.rows[0].id;
      console.log('✅ Using existing sprint');
    }

    // Add sample ticket using correct column names
    await pool.query(`
      INSERT INTO tickets (user_id, ticket_id, ticket_key, summary, description, status, issue_type, priority, project_id, sprint_id) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    `, [
      '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf', // user_id
      'TICKET-001', // ticket_id
      'TICKET-001', // ticket_key
      'Sample Ticket', // summary
      'A sample ticket for testing the application', // description
      'open', // status
      'Task', // issue_type
      'Medium', // priority
      projectId, // project_id
      sprintId // sprint_id
    ]);
    console.log('✅ Created sample ticket');

    // Add sample approval request
    await pool.query(`
      INSERT INTO approval_requests (title, description, project_id, requested_by) 
      VALUES ($1, $2, $3, $4)
    `, [
      'Sample Approval Request',
      'A sample approval request for testing',
      projectId,
      '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf'
    ]);
    console.log('✅ Created sample approval request');

    // Add sample notification
    await pool.query(`
      INSERT INTO notifications (user_id, title, message, type) 
      VALUES ($1, $2, $3, $4)
    `, [
      '9a2aa39b-40b7-4e60-bf4d-70ce342f6ccf',
      'Welcome to Flow-Space!',
      'Your account has been successfully set up.',
      'info'
    ]);
    console.log('✅ Created sample notification');

    console.log('🎉 Sample data added successfully!');
    
  } catch (error) {
    console.error('❌ Error adding sample data:', error);
  } finally {
    await pool.end();
  }
}

addSampleData();
