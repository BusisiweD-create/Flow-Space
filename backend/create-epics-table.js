require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function createMissingTables() {
  try {
    console.log('🚀 Creating missing tables...\n');

    // Create epics table
    console.log('📦 Creating epics table...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS epics (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'draft',
        project_id UUID,
        sprint_ids UUID[] DEFAULT '{}',
        deliverable_ids UUID[] DEFAULT '{}',
        start_date TIMESTAMP,
        target_date TIMESTAMP,
        created_by UUID,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('   ✅ epics table created');

    // Create indexes for epics
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_epics_project ON epics(project_id)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_epics_status ON epics(status)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_epics_created_by ON epics(created_by)`);
    console.log('   ✅ epics indexes created');

    // Create change_requests table
    console.log('📦 Creating change_requests table...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS change_requests (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID,
        requested_by UUID,
        status VARCHAR(50) DEFAULT 'open',
        description TEXT NOT NULL,
        priority VARCHAR(20) DEFAULT 'medium',
        resolution TEXT,
        resolved_by UUID,
        resolved_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('   ✅ change_requests table created');

    // Create indexes for change_requests
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_change_requests_report ON change_requests(report_id)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_change_requests_status ON change_requests(status)`);
    console.log('   ✅ change_requests indexes created');

    // Add epic_id column to deliverables if not exists
    console.log('📦 Adding epic_id to deliverables...');
    try {
      await pool.query(`ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS epic_id UUID`);
      console.log('   ✅ epic_id column added to deliverables');
    } catch (e) {
      console.log('   ⚠️ epic_id column may already exist');
    }

    // Verify all tables
    console.log('\n📊 Verifying all tables...');
    const tableCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('\n✅ All tables in database:');
    tableCheck.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });

    // Check epics columns
    console.log('\n📋 Epics table columns:');
    const epicColumns = await pool.query(`
      SELECT column_name, data_type
      FROM information_schema.columns 
      WHERE table_name = 'epics'
      ORDER BY ordinal_position
    `);
    
    epicColumns.rows.forEach(row => {
      console.log(`   ✓ ${row.column_name} (${row.data_type})`);
    });

    console.log('\n🎉 All tables created successfully!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

createMissingTables();
