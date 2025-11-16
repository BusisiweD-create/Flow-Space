// Create sign_off_reports and deliverables tables if they don't exist
const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

function getPool() {
  return new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'flow_space',
    max: 10,
  });
}

async function ensureExtensions(pool) {
  try {
    await pool.query("CREATE EXTENSION IF NOT EXISTS pgcrypto");
  } catch (err) {
    console.log('Note: pgcrypto extension might already exist or not available');
  }
}

async function createDeliverablesTable(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS deliverables (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title VARCHAR(255) NOT NULL,
      description TEXT,
      status VARCHAR(50) DEFAULT 'draft',
      project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
      created_by UUID REFERENCES users(id) ON DELETE SET NULL,
      assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
      due_date TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      definition_of_done JSONB DEFAULT '[]',
      evidence JSONB DEFAULT '[]',
      readiness_gates JSONB DEFAULT '[]',
      sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
      priority VARCHAR(50) DEFAULT 'medium',
      progress INTEGER DEFAULT 0
    )
  `);

  // Add indexes
  try {
    await pool.query('CREATE INDEX IF NOT EXISTS idx_deliverables_project ON deliverables(project_id)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_deliverables_status ON deliverables(status)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_deliverables_created_by ON deliverables(created_by)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_deliverables_sprint ON deliverables(sprint_id)');
  } catch (err) {
    console.log('Note: Some indexes might already exist:', err.message);
  }
}

async function createSignOffReportsTable(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS sign_off_reports (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
      created_by UUID REFERENCES users(id) ON DELETE SET NULL,
      status VARCHAR(50) DEFAULT 'draft',
      report_title VARCHAR(255),
      report_content TEXT,
      content JSONB DEFAULT '{}',
      evidence JSONB DEFAULT '[]',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      submitted_at TIMESTAMP,
      approved_at TIMESTAMP
    )
  `);

  // Add indexes
  try {
    await pool.query('CREATE INDEX IF NOT EXISTS idx_sign_off_reports_deliverable ON sign_off_reports(deliverable_id)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_sign_off_reports_status ON sign_off_reports(status)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_sign_off_reports_created_by ON sign_off_reports(created_by)');
  } catch (err) {
    console.log('Note: Some indexes might already exist:', err.message);
  }
}

async function createClientReviewsTable(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS client_reviews (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
      reviewer_id UUID REFERENCES users(id) ON DELETE SET NULL,
      status VARCHAR(50) DEFAULT 'pending',
      feedback TEXT,
      approved_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Add index
  try {
    await pool.query('CREATE INDEX IF NOT EXISTS idx_client_reviews_report ON client_reviews(report_id)');
  } catch (err) {
    console.log('Note: Index might already exist:', err.message);
  }
}

async function run() {
  const pool = getPool();
  
  try {
    console.log('🔧 Ensuring database extensions...');
    await ensureExtensions(pool);
    
    console.log('📋 Creating deliverables table...');
    await createDeliverablesTable(pool);
    console.log('✅ Deliverables table ready');
    
    console.log('📋 Creating sign_off_reports table...');
    await createSignOffReportsTable(pool);
    console.log('✅ Sign-off reports table ready');
    
    console.log('📋 Creating client_reviews table...');
    await createClientReviewsTable(pool);
    console.log('✅ Client reviews table ready');
    
    console.log('✅ Migration completed successfully!');
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  run().catch(console.error);
}

module.exports = { run };

