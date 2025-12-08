const { Pool } = require('pg');
const dbConfig = require('../database-config');

async function run() {
  console.log('🚀 Ensuring core tables (users, projects, sign_off_reports, etc.) exist...');
  const pool = new Pool(dbConfig);
  const client = await pool.connect();

  try {
    await client.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');

    const sql = `
    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL DEFAULT 'teamMember',
      avatar_url TEXT,
      is_active BOOLEAN DEFAULT true,
      email_verified BOOLEAN DEFAULT false,
      email_verified_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_login_at TIMESTAMP,
      preferences JSONB DEFAULT '{}',
      project_ids UUID[] DEFAULT '{}'
    );

    CREATE TABLE IF NOT EXISTS projects (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      description TEXT,
      owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
      status VARCHAR(50) DEFAULT 'active',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS deliverables (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title VARCHAR(255) NOT NULL,
      description TEXT,
      status VARCHAR(50) DEFAULT 'draft',
      project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
      created_by UUID REFERENCES users(id) ON DELETE CASCADE,
      assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
      due_date TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      definition_of_done JSONB DEFAULT '[]',
      evidence JSONB DEFAULT '[]',
      readiness_gates JSONB DEFAULT '[]'
    );

    CREATE TABLE IF NOT EXISTS sprints (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
      start_date TIMESTAMP NOT NULL,
      end_date TIMESTAMP NOT NULL,
      committed_points INTEGER DEFAULT 0,
      completed_points INTEGER DEFAULT 0,
      velocity DECIMAL(5,2) DEFAULT 0,
      test_pass_rate DECIMAL(5,2) DEFAULT 0,
      defect_count INTEGER DEFAULT 0,
      status VARCHAR(50) DEFAULT 'planning',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sprint_deliverables (
      id SERIAL PRIMARY KEY,
      sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
      deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
      points INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(sprint_id, deliverable_id)
    );

    CREATE TABLE IF NOT EXISTS sign_off_reports (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
      created_by UUID REFERENCES users(id) ON DELETE CASCADE,
      status VARCHAR(50) DEFAULT 'draft',
      content JSONB DEFAULT '{}',
      evidence JSONB DEFAULT '[]',
      submitted_at TIMESTAMP,
      approved_at TIMESTAMP,
      last_reminder_at TIMESTAMP,
      escalated_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS client_reviews (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
      reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
      status VARCHAR(50) DEFAULT 'pending',
      feedback TEXT,
      approved_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES users(id) ON DELETE CASCADE,
      title VARCHAR(255) NOT NULL,
      message TEXT,
      type VARCHAR(50) DEFAULT 'info',
      is_read BOOLEAN DEFAULT false,
      action_url TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS audit_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES users(id) ON DELETE SET NULL,
      action VARCHAR(100) NOT NULL,
      resource_type VARCHAR(50),
      resource_id UUID,
      details JSONB DEFAULT '{}',
      ip_address INET,
      user_agent TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    `;

    await client.query(sql);
    console.log('✅ Core tables ensured.');
  } catch (err) {
    console.error('❌ Error ensuring core tables:', err.message);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  run().catch(err => {
    console.error('❌ Core tables migration failed:', err.message);
    process.exit(1);
  });
}

module.exports = { run };
