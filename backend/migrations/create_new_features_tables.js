/**
 * Migration script to create tables for new features:
 * - DocuSign integration
 * - Digital signatures
 * - Report exports
 * 
 * Run this with: node migrations/create_new_features_tables.js
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

async function createDocuSignEnvelopesTable() {
  console.log('Creating docusign_envelopes table...');
  
  await pool.query(`
    CREATE TABLE IF NOT EXISTS docusign_envelopes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
      envelope_id VARCHAR(255) NOT NULL UNIQUE,
      status VARCHAR(50) DEFAULT 'created',
      signer_email VARCHAR(255) NOT NULL,
      signer_name VARCHAR(255) NOT NULL,
      signer_role VARCHAR(50),
      created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      sent_at TIMESTAMP,
      delivered_at TIMESTAMP,
      signed_at TIMESTAMP,
      completed_at TIMESTAMP,
      declined_at TIMESTAMP,
      decline_reason TEXT,
      voided_at TIMESTAMP,
      void_reason TEXT,
      metadata JSONB DEFAULT '{}',
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      CONSTRAINT unique_report_envelope UNIQUE(report_id, envelope_id)
    )
  `);

  // Create indexes
  await pool.query('CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_report ON docusign_envelopes(report_id)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_envelope_id ON docusign_envelopes(envelope_id)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_status ON docusign_envelopes(status)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_signer_email ON docusign_envelopes(signer_email)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_created_by ON docusign_envelopes(created_by)');
  
  console.log('✅ docusign_envelopes table created');
}

async function createDigitalSignaturesTable() {
  console.log('Creating digital_signatures table...');
  
  await pool.query(`
    CREATE TABLE IF NOT EXISTS digital_signatures (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
      signer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      signer_role VARCHAR(50) NOT NULL,
      signature_type VARCHAR(50) NOT NULL DEFAULT 'manual',
      signature_data TEXT NOT NULL,
      signature_hash VARCHAR(255),
      ip_address VARCHAR(45),
      user_agent TEXT,
      signed_at TIMESTAMP NOT NULL DEFAULT NOW(),
      expires_at TIMESTAMP,
      is_valid BOOLEAN DEFAULT TRUE,
      metadata JSONB DEFAULT '{}',
      created_at TIMESTAMP DEFAULT NOW(),
      CONSTRAINT unique_report_signer UNIQUE(report_id, signer_id, signer_role)
    )
  `);

  // Create indexes
  await pool.query('CREATE INDEX IF NOT EXISTS idx_digital_signatures_report ON digital_signatures(report_id)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_digital_signatures_signer ON digital_signatures(signer_id)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_digital_signatures_type ON digital_signatures(signature_type)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_digital_signatures_valid ON digital_signatures(is_valid)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_digital_signatures_signed_at ON digital_signatures(signed_at)');
  
  console.log('✅ digital_signatures table created');
}

async function createReportExportsTable() {
  console.log('Creating report_exports table...');
  
  await pool.query(`
    CREATE TABLE IF NOT EXISTS report_exports (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
      exported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      export_format VARCHAR(50) NOT NULL,
      export_type VARCHAR(50) NOT NULL,
      file_path TEXT,
      file_size BIGINT,
      file_hash VARCHAR(255),
      metadata JSONB DEFAULT '{}',
      created_at TIMESTAMP DEFAULT NOW(),
      CONSTRAINT valid_export_format CHECK (export_format IN ('pdf', 'docx', 'xlsx', 'csv', 'html', 'json')),
      CONSTRAINT valid_export_type CHECK (export_type IN ('download', 'print', 'email', 'share'))
    )
  `);

  // Create indexes
  await pool.query('CREATE INDEX IF NOT EXISTS idx_report_exports_report ON report_exports(report_id)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_report_exports_exported_by ON report_exports(exported_by)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_report_exports_format ON report_exports(export_format)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_report_exports_created_at ON report_exports(created_at)');
  
  console.log('✅ report_exports table created');
}

async function updateExistingTables() {
  console.log('Updating existing tables...');
  
  // Add columns to sign_off_reports if they don't exist
  const signOffReportsColumns = await pool.query(`
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'sign_off_reports'
  `);
  
  const existingColumns = signOffReportsColumns.rows.map(row => row.column_name);
  
  if (!existingColumns.includes('submitted_at')) {
    await pool.query('ALTER TABLE sign_off_reports ADD COLUMN submitted_at TIMESTAMP');
    console.log('✅ Added submitted_at column to sign_off_reports');
  }
  
  if (!existingColumns.includes('approved_at')) {
    await pool.query('ALTER TABLE sign_off_reports ADD COLUMN approved_at TIMESTAMP');
    console.log('✅ Added approved_at column to sign_off_reports');
  }
  
  if (!existingColumns.includes('docusign_envelope_id')) {
    await pool.query('ALTER TABLE sign_off_reports ADD COLUMN docusign_envelope_id VARCHAR(255)');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_sign_off_reports_docusign_envelope ON sign_off_reports(docusign_envelope_id)');
    console.log('✅ Added docusign_envelope_id column to sign_off_reports');
  }
  
  // Add columns to client_reviews if they don't exist
  const clientReviewsColumns = await pool.query(`
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'client_reviews'
  `);
  
  const existingClientReviewColumns = clientReviewsColumns.rows.map(row => row.column_name);
  
  if (!existingClientReviewColumns.includes('digital_signature')) {
    await pool.query('ALTER TABLE client_reviews ADD COLUMN digital_signature TEXT');
    console.log('✅ Added digital_signature column to client_reviews');
  }
  
  if (!existingClientReviewColumns.includes('signature_date')) {
    await pool.query('ALTER TABLE client_reviews ADD COLUMN signature_date TIMESTAMP');
    console.log('✅ Added signature_date column to client_reviews');
  }
  
  if (!existingClientReviewColumns.includes('updated_at')) {
    await pool.query('ALTER TABLE client_reviews ADD COLUMN updated_at TIMESTAMP DEFAULT NOW()');
    console.log('✅ Added updated_at column to client_reviews');
  }
}

async function createTriggers() {
  console.log('Creating triggers...');
  
  // Create function for updating updated_at
  await pool.query(`
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    $$ language 'plpgsql'
  `);
  
  // Create triggers
  await pool.query(`
    DROP TRIGGER IF EXISTS update_docusign_envelopes_updated_at ON docusign_envelopes;
    CREATE TRIGGER update_docusign_envelopes_updated_at
      BEFORE UPDATE ON docusign_envelopes
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column()
  `);
  
  await pool.query(`
    DROP TRIGGER IF EXISTS update_client_reviews_updated_at ON client_reviews;
    CREATE TRIGGER update_client_reviews_updated_at
      BEFORE UPDATE ON client_reviews
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column()
  `);
  
  console.log('✅ Triggers created');
}

async function createViews() {
  console.log('Creating views...');
  
  // View for reports with DocuSign status
  await pool.query(`
    CREATE OR REPLACE VIEW reports_with_docusign AS
    SELECT 
      r.id,
      r.deliverable_id,
      r.created_by,
      r.status,
      r.submitted_at,
      r.approved_at,
      r.docusign_envelope_id,
      de.envelope_id,
      de.status as docusign_status,
      de.signer_email,
      de.signer_name,
      de.signed_at as docusign_signed_at,
      de.completed_at as docusign_completed_at,
      r.created_at,
      r.updated_at
    FROM sign_off_reports r
    LEFT JOIN docusign_envelopes de ON r.docusign_envelope_id = de.envelope_id
  `);
  
  // View for reports with digital signatures
  await pool.query(`
    CREATE OR REPLACE VIEW reports_with_signatures AS
    SELECT 
      r.id as report_id,
      r.status,
      ds_dl.id as delivery_lead_signature_id,
      ds_dl.signer_id as delivery_lead_signer_id,
      ds_dl.signed_at as delivery_lead_signed_at,
      ds_cr.id as client_reviewer_signature_id,
      ds_cr.signer_id as client_reviewer_signer_id,
      ds_cr.signed_at as client_reviewer_signed_at,
      CASE 
        WHEN ds_dl.id IS NOT NULL AND ds_cr.id IS NOT NULL THEN TRUE
        ELSE FALSE
      END as fully_signed
    FROM sign_off_reports r
    LEFT JOIN digital_signatures ds_dl ON r.id = ds_dl.report_id AND ds_dl.signer_role = 'deliveryLead'
    LEFT JOIN digital_signatures ds_cr ON r.id = ds_cr.report_id AND ds_cr.signer_role = 'clientReviewer'
  `);
  
  // View for export statistics
  await pool.query(`
    CREATE OR REPLACE VIEW report_export_statistics AS
    SELECT 
      report_id,
      COUNT(*) as total_exports,
      COUNT(DISTINCT exported_by) as unique_exporters,
      COUNT(*) FILTER (WHERE export_format = 'pdf') as pdf_exports,
      COUNT(*) FILTER (WHERE export_format = 'docx') as docx_exports,
      COUNT(*) FILTER (WHERE export_type = 'download') as downloads,
      COUNT(*) FILTER (WHERE export_type = 'print') as prints,
      MAX(created_at) as last_exported_at
    FROM report_exports
    GROUP BY report_id
  `);
  
  console.log('✅ Views created');
}

async function run() {
  try {
    console.log('🚀 Starting migration: Creating new features tables...\n');
    
    await createDocuSignEnvelopesTable();
    await createDigitalSignaturesTable();
    await createReportExportsTable();
    await updateExistingTables();
    await createTriggers();
    await createViews();
    
    console.log('\n✅ Migration completed successfully!');
    console.log('\n📊 Summary:');
    console.log('   - Created docusign_envelopes table');
    console.log('   - Created digital_signatures table');
    console.log('   - Created report_exports table');
    console.log('   - Updated existing tables with new columns');
    console.log('   - Created triggers for automatic timestamp updates');
    console.log('   - Created views for easier querying');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run migration
if (require.main === module) {
  run().catch(console.error);
}

module.exports = {
  createDocuSignEnvelopesTable,
  createDigitalSignaturesTable,
  createReportExportsTable,
  updateExistingTables,
  createTriggers,
  createViews,
  run
};

