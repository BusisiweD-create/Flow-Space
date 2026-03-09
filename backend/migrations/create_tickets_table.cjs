/**
 * Flow-Space Database Migration: Create Tickets Table
 * 
 * This migration creates the missing tickets table for sprint task management
 * 
 * Run this with: node migrations/create_tickets_table.js
 */

const { Pool } = require('pg');
require('dotenv').config();

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });

async function createTicketsTable() {
  const client = await pool.connect();
  
  try {
    console.log('🎫 Creating tickets table...');
    
    await client.query('BEGIN');
    
    // Create tickets table
    const createTicketsTable = `
      CREATE TABLE IF NOT EXISTS tickets (
        ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_key VARCHAR(50) UNIQUE NOT NULL,
        summary VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'To Do',
        issue_type VARCHAR(50) DEFAULT 'Task',
        priority VARCHAR(20) DEFAULT 'Medium',
        assignee VARCHAR(255),
        reporter VARCHAR(255) NOT NULL,
        sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
        project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `;
    
    await client.query(createTicketsTable);
    console.log('✅ Tickets table created');
    
    // Create indexes
    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_tickets_sprint ON tickets(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_project ON tickets(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_assignee ON tickets(assignee)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_reporter ON tickets(reporter)'
    ];
    
    for (const index of indexes) {
      await client.query(index);
    }
    console.log('✅ Tickets table indexes created');
    
    // Create trigger for updated_at
    const triggerExists = await client.query(`
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'update_tickets_updated_at'
    `);
    
    if (triggerExists.rows.length === 0) {
      await client.query(`
        CREATE TRIGGER update_tickets_updated_at 
        BEFORE UPDATE ON tickets
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);
      console.log('✅ Tickets table trigger created');
    }
    
    await client.query('COMMIT');
    
    console.log('\n🎉 Tickets table migration completed successfully!');
    console.log('📋 Table: tickets');
    console.log('🔑 Columns: ticket_id, ticket_key, summary, description, status, issue_type, priority, assignee, reporter, sprint_id, project_id, user_id, created_at, updated_at');
    console.log('📊 Indexes: sprint_id, project_id, status, assignee, reporter');
    console.log('\n💡 You can now create and manage tickets for sprints!\n');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error creating tickets table:', error.message);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    
    if (error.code === '42P01') {
      console.log('\n💡 This error suggests a referenced table (sprints, projects, users) might not exist.');
      console.log('   Please ensure those tables are created first.');
    }
    
    throw error;
    
  } finally {
    client.release();
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  createTicketsTable()
    .then(() => {
      console.log('✅ Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { createTicketsTable };
