require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function createTables() {
  try {
    console.log('🚀 Creating sprint-related tables...\n');

    // Create sprint_deliverables junction table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sprint_deliverables (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sprint_id UUID NOT NULL,
        deliverable_id UUID NOT NULL,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(sprint_id, deliverable_id)
      )
    `);
    console.log('✅ sprint_deliverables table created');

    // Create sprint_metrics table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sprint_metrics (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sprint_id UUID NOT NULL,
        committed_points INTEGER DEFAULT 0,
        completed_points INTEGER DEFAULT 0,
        carried_over_points INTEGER DEFAULT 0,
        test_pass_rate DECIMAL(5,2) DEFAULT 0,
        defects_opened INTEGER DEFAULT 0,
        defects_closed INTEGER DEFAULT 0,
        critical_defects INTEGER DEFAULT 0,
        high_defects INTEGER DEFAULT 0,
        medium_defects INTEGER DEFAULT 0,
        low_defects INTEGER DEFAULT 0,
        code_review_completion DECIMAL(5,2) DEFAULT 0,
        documentation_status DECIMAL(5,2) DEFAULT 0,
        risks TEXT,
        mitigations TEXT,
        scope_changes TEXT,
        blockers TEXT,
        decisions TEXT,
        uat_notes TEXT,
        recorded_at TIMESTAMP DEFAULT NOW(),
        recorded_by UUID,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('✅ sprint_metrics table created');

    // Create index on sprint_id for faster lookups
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_sprint_metrics_sprint_id ON sprint_metrics(sprint_id)
    `);
    console.log('✅ Index on sprint_metrics created');

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_sprint_deliverables_sprint_id ON sprint_deliverables(sprint_id)
    `);
    console.log('✅ Index on sprint_deliverables created');

    // Verify tables exist
    const tables = await pool.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('sprint_deliverables', 'sprint_metrics')
    `);
    
    console.log('\n📋 Verified tables:');
    tables.rows.forEach(row => console.log(`   - ${row.table_name}`));

    console.log('\n🎉 All sprint tables created successfully!');
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

createTables();
