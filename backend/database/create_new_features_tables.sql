-- Create tables for new features: DocuSign integration, digital signatures, and report exports
-- Run this in the flow_space database
-- Run this after the base tables are created

-- Make sure you're connected to the correct database
-- \c flow_space

-- ============================================================================
-- 1. DOCUSIGN ENVELOPES TABLE
-- ============================================================================
-- Tracks DocuSign envelope information for reports
CREATE TABLE IF NOT EXISTS docusign_envelopes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    envelope_id VARCHAR(255) NOT NULL UNIQUE, -- DocuSign envelope ID
    status VARCHAR(50) DEFAULT 'created', -- created, sent, delivered, signed, completed, declined, voided
    signer_email VARCHAR(255) NOT NULL,
    signer_name VARCHAR(255) NOT NULL,
    signer_role VARCHAR(50), -- deliveryLead, clientReviewer, etc.
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    signed_at TIMESTAMP,
    completed_at TIMESTAMP,
    declined_at TIMESTAMP,
    decline_reason TEXT,
    voided_at TIMESTAMP,
    void_reason TEXT,
    metadata JSONB DEFAULT '{}', -- Store additional DocuSign response data
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_report_envelope UNIQUE(report_id, envelope_id)
);

-- Indexes for docusign_envelopes
CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_report ON docusign_envelopes(report_id);
CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_envelope_id ON docusign_envelopes(envelope_id);
CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_status ON docusign_envelopes(status);
CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_signer_email ON docusign_envelopes(signer_email);
CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_created_by ON docusign_envelopes(created_by);

-- ============================================================================
-- 2. DIGITAL SIGNATURES TABLE
-- ============================================================================
-- Stores digital signatures for reports (both delivery lead and client reviewer signatures)
CREATE TABLE IF NOT EXISTS digital_signatures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    signer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    signer_role VARCHAR(50) NOT NULL, -- deliveryLead, clientReviewer, etc.
    signature_type VARCHAR(50) NOT NULL DEFAULT 'manual', -- manual, docusign, eid, etc.
    signature_data TEXT NOT NULL, -- Base64 encoded signature image or DocuSign signature data
    signature_hash VARCHAR(255), -- SHA-256 hash of signature for verification
    ip_address VARCHAR(45), -- IPv4 or IPv6 address
    user_agent TEXT, -- Browser/client information
    signed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP, -- Optional expiration date
    is_valid BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}', -- Additional signature metadata
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_report_signer UNIQUE(report_id, signer_id, signer_role)
);

-- Indexes for digital_signatures
CREATE INDEX IF NOT EXISTS idx_digital_signatures_report ON digital_signatures(report_id);
CREATE INDEX IF NOT EXISTS idx_digital_signatures_signer ON digital_signatures(signer_id);
CREATE INDEX IF NOT EXISTS idx_digital_signatures_type ON digital_signatures(signature_type);
CREATE INDEX IF NOT EXISTS idx_digital_signatures_valid ON digital_signatures(is_valid);
CREATE INDEX IF NOT EXISTS idx_digital_signatures_signed_at ON digital_signatures(signed_at);

-- ============================================================================
-- 3. REPORT EXPORTS TABLE
-- ============================================================================
-- Tracks report export history for audit purposes
CREATE TABLE IF NOT EXISTS report_exports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
    exported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    export_format VARCHAR(50) NOT NULL, -- pdf, docx, xlsx, csv, etc.
    export_type VARCHAR(50) NOT NULL, -- download, print, email, share
    file_path TEXT, -- Path to exported file (if saved)
    file_size BIGINT, -- File size in bytes
    file_hash VARCHAR(255), -- SHA-256 hash of exported file
    metadata JSONB DEFAULT '{}', -- Export options, filters, etc.
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT valid_export_format CHECK (export_format IN ('pdf', 'docx', 'xlsx', 'csv', 'html', 'json')),
    CONSTRAINT valid_export_type CHECK (export_type IN ('download', 'print', 'email', 'share'))
);

-- Indexes for report_exports
CREATE INDEX IF NOT EXISTS idx_report_exports_report ON report_exports(report_id);
CREATE INDEX IF NOT EXISTS idx_report_exports_exported_by ON report_exports(exported_by);
CREATE INDEX IF NOT EXISTS idx_report_exports_format ON report_exports(export_format);
CREATE INDEX IF NOT EXISTS idx_report_exports_created_at ON report_exports(created_at);

-- ============================================================================
-- 4. UPDATE EXISTING TABLES
-- ============================================================================

-- Add columns to sign_off_reports if they don't exist
DO $$ 
BEGIN
    -- Add submitted_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sign_off_reports' AND column_name = 'submitted_at'
    ) THEN
        ALTER TABLE sign_off_reports ADD COLUMN submitted_at TIMESTAMP;
    END IF;
    
    -- Add approved_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sign_off_reports' AND column_name = 'approved_at'
    ) THEN
        ALTER TABLE sign_off_reports ADD COLUMN approved_at TIMESTAMP;
    END IF;
    
    -- Add docusign_envelope_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sign_off_reports' AND column_name = 'docusign_envelope_id'
    ) THEN
        ALTER TABLE sign_off_reports ADD COLUMN docusign_envelope_id VARCHAR(255);
        CREATE INDEX IF NOT EXISTS idx_sign_off_reports_docusign_envelope ON sign_off_reports(docusign_envelope_id);
    END IF;
END $$;

-- Add columns to client_reviews if they don't exist
DO $$ 
BEGIN
    -- Add digital_signature column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'client_reviews' AND column_name = 'digital_signature'
    ) THEN
        ALTER TABLE client_reviews ADD COLUMN digital_signature TEXT;
    END IF;
    
    -- Add signature_date column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'client_reviews' AND column_name = 'signature_date'
    ) THEN
        ALTER TABLE client_reviews ADD COLUMN signature_date TIMESTAMP;
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'client_reviews' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE client_reviews ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- ============================================================================
-- 5. TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_docusign_envelopes_updated_at ON docusign_envelopes;
CREATE TRIGGER update_docusign_envelopes_updated_at
    BEFORE UPDATE ON docusign_envelopes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_client_reviews_updated_at ON client_reviews;
CREATE TRIGGER update_client_reviews_updated_at
    BEFORE UPDATE ON client_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. VIEWS FOR EASIER QUERYING
-- ============================================================================

-- View for reports with DocuSign status
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
LEFT JOIN docusign_envelopes de ON r.docusign_envelope_id = de.envelope_id;

-- View for reports with digital signatures
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
LEFT JOIN digital_signatures ds_cr ON r.id = ds_cr.report_id AND ds_cr.signer_role = 'clientReviewer';

-- View for export statistics
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
GROUP BY report_id;

-- ============================================================================
-- 7. COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE docusign_envelopes IS 'Tracks DocuSign envelope information for report signing workflow';
COMMENT ON TABLE digital_signatures IS 'Stores digital signatures for reports from both delivery leads and client reviewers';
COMMENT ON TABLE report_exports IS 'Tracks report export history for audit and analytics purposes';

COMMENT ON COLUMN docusign_envelopes.envelope_id IS 'DocuSign envelope ID (unique identifier from DocuSign API)';
COMMENT ON COLUMN docusign_envelopes.status IS 'DocuSign envelope status: created, sent, delivered, signed, completed, declined, voided';
COMMENT ON COLUMN digital_signatures.signature_data IS 'Base64 encoded signature image or DocuSign signature data';
COMMENT ON COLUMN digital_signatures.signature_hash IS 'SHA-256 hash of signature for verification and integrity checking';
COMMENT ON COLUMN report_exports.file_hash IS 'SHA-256 hash of exported file for verification';

-- ============================================================================
-- 8. SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================================================
-- Uncomment below to insert sample data for testing

/*
-- Sample DocuSign envelope (replace with actual data)
INSERT INTO docusign_envelopes (report_id, envelope_id, status, signer_email, signer_name, signer_role, created_by)
SELECT 
    r.id,
    'sample-envelope-' || gen_random_uuid()::text,
    'sent',
    'signer@example.com',
    'John Doe',
    'clientReviewer',
    r.created_by
FROM sign_off_reports r
WHERE r.status = 'submitted'
LIMIT 1;

-- Sample digital signature (replace with actual data)
INSERT INTO digital_signatures (report_id, signer_id, signer_role, signature_type, signature_data)
SELECT 
    r.id,
    r.created_by,
    'deliveryLead',
    'manual',
    'sample_base64_signature_data'
FROM sign_off_reports r
WHERE r.status = 'draft'
LIMIT 1;
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify tables were created
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_name IN ('docusign_envelopes', 'digital_signatures', 'report_exports')
ORDER BY table_name;

-- Verify indexes were created
SELECT 
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'public'
    AND tablename IN ('docusign_envelopes', 'digital_signatures', 'report_exports')
ORDER BY tablename, indexname;

