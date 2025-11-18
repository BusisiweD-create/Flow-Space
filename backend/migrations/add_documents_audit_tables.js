// Create/alter tables for repository files and audit logs
const { Pool } = require('pg');
require('dotenv').config({ path: __dirname + '/../.env' });

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
  // Enable pgcrypto (for gen_random_uuid) if available; ignore errors if not
  try {
    await pool.query("CREATE EXTENSION IF NOT EXISTS pgcrypto");
  } catch (_) {}
}

async function createRepositoryFiles(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS repository_files (
      id BIGSERIAL PRIMARY KEY,
      project_id UUID NULL,
      file_name TEXT,
      file_path TEXT,
      file_type TEXT,
      file_size BIGINT,
      content_hash TEXT,
      uploaded_by UUID,
      description TEXT,
      tags TEXT,
      uploaded_at TIMESTAMPTZ,
      last_modified TIMESTAMPTZ,
      is_active BOOLEAN
    )
  `);

  // Ensure required columns exist with defaults
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS last_modified TIMESTAMPTZ NOT NULL DEFAULT NOW()`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE`);
  // Handle existing old schema columns - make them nullable if they exist and are NOT NULL
  const oldColumns = ['filename', 'original_filename'];
  for (const colName of oldColumns) {
    try {
      const checkResult = await pool.query(`
        SELECT is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'repository_files' AND column_name = $1
      `, [colName]);
      
      if (checkResult.rows.length > 0 && checkResult.rows[0].is_nullable === 'NO') {
        await pool.query(`ALTER TABLE repository_files ALTER COLUMN ${colName} DROP NOT NULL`);
        console.log(`✅ Made ${colName} column nullable`);
      }
    } catch (e) {
      // Column might not exist or already nullable, ignore
      console.log(`ℹ️  ${colName} column check:`, e.message);
    }
  }
  
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS file_name TEXT`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS file_path TEXT`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS file_type TEXT`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS file_size BIGINT`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS content_hash TEXT`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS uploaded_by UUID`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS description TEXT`);
  await pool.query(`ALTER TABLE repository_files ADD COLUMN IF NOT EXISTS tags TEXT`);
  
  // Sync filename from file_name if filename exists but is null
  try {
    await pool.query(`
      UPDATE repository_files 
      SET filename = file_name 
      WHERE filename IS NULL AND file_name IS NOT NULL
    `);
  } catch (e) {
    // Ignore if filename column doesn't exist
  }

  await pool.query(`CREATE INDEX IF NOT EXISTS idx_repository_files_uploaded_by ON repository_files(uploaded_by)`);
  await pool.query(`CREATE INDEX IF NOT EXISTS idx_repository_files_project ON repository_files(project_id)`);
  await pool.query(`CREATE INDEX IF NOT EXISTS idx_repository_files_uploaded_at ON repository_files(uploaded_at DESC)`);
}

async function createAuditLogs(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS audit_logs (
      id BIGSERIAL PRIMARY KEY,
      user_id UUID NOT NULL,
      action TEXT NOT NULL,
      resource_type TEXT NOT NULL,
      resource_id TEXT NOT NULL,
      details JSONB NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await pool.query(`CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id)`);
  await pool.query(`CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC)`);
}

async function createProjectMembers(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS project_members (
      id BIGSERIAL PRIMARY KEY,
      project_id UUID NOT NULL,
      user_id UUID NOT NULL,
      role TEXT NULL,
      added_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await pool.query(`CREATE INDEX IF NOT EXISTS idx_project_members_project ON project_members(project_id)`);
  await pool.query(`CREATE INDEX IF NOT EXISTS idx_project_members_user ON project_members(user_id)`);
}

async function alterTicketsAddUserIdIfMissing(pool) {
  // Add user_id to tickets if it doesn't exist
  const res = await pool.query(`
    SELECT 1 FROM information_schema.columns 
    WHERE table_name='tickets' AND column_name='user_id'
  `);
  if (res.rowCount === 0) {
    await pool.query(`ALTER TABLE tickets ADD COLUMN user_id UUID NULL`);
    // Optional index
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id)`);
  }
}

async function run() {
  const pool = getPool();
  try {
    console.log('🔧 Applying documents & audit schema updates...');
    await ensureExtensions(pool);
    await createRepositoryFiles(pool);
    await createAuditLogs(pool);
    await alterTicketsAddUserIdIfMissing(pool);
    await createProjectMembers(pool);
    console.log('✅ Documents & audit tables are up to date.');
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

run();


