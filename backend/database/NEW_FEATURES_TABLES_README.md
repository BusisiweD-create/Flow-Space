# New Features Database Tables

This document describes the database tables created for the new features:
- DocuSign Integration
- Digital Signatures
- Report Exports

## 📋 Tables Created

### 1. `docusign_envelopes`
Tracks DocuSign envelope information for report signing workflow.

**Columns:**
- `id` - UUID primary key
- `report_id` - Foreign key to `sign_off_reports`
- `envelope_id` - DocuSign envelope ID (unique)
- `status` - Envelope status (created, sent, delivered, signed, completed, declined, voided)
- `signer_email` - Email of the signer
- `signer_name` - Name of the signer
- `signer_role` - Role of the signer (deliveryLead, clientReviewer, etc.)
- `created_by` - User who created the envelope
- `sent_at`, `delivered_at`, `signed_at`, `completed_at`, `declined_at`, `voided_at` - Timestamps for status changes
- `decline_reason`, `void_reason` - Reasons for decline/void
- `metadata` - JSONB field for additional DocuSign response data
- `created_at`, `updated_at` - Timestamps

**Indexes:**
- `idx_docusign_envelopes_report` - On `report_id`
- `idx_docusign_envelopes_envelope_id` - On `envelope_id`
- `idx_docusign_envelopes_status` - On `status`
- `idx_docusign_envelopes_signer_email` - On `signer_email`
- `idx_docusign_envelopes_created_by` - On `created_by`

### 2. `digital_signatures`
Stores digital signatures for reports from both delivery leads and client reviewers.

**Columns:**
- `id` - UUID primary key
- `report_id` - Foreign key to `sign_off_reports`
- `signer_id` - Foreign key to `users`
- `signer_role` - Role of the signer (deliveryLead, clientReviewer, etc.)
- `signature_type` - Type of signature (manual, docusign, eid, etc.)
- `signature_data` - Base64 encoded signature image or DocuSign signature data
- `signature_hash` - SHA-256 hash of signature for verification
- `ip_address` - IPv4 or IPv6 address of signer
- `user_agent` - Browser/client information
- `signed_at` - Timestamp when signature was created
- `expires_at` - Optional expiration date
- `is_valid` - Boolean flag for signature validity
- `metadata` - JSONB field for additional signature metadata
- `created_at` - Timestamp

**Constraints:**
- Unique constraint on `(report_id, signer_id, signer_role)` - One signature per signer per report

**Indexes:**
- `idx_digital_signatures_report` - On `report_id`
- `idx_digital_signatures_signer` - On `signer_id`
- `idx_digital_signatures_type` - On `signature_type`
- `idx_digital_signatures_valid` - On `is_valid`
- `idx_digital_signatures_signed_at` - On `signed_at`

### 3. `report_exports`
Tracks report export history for audit and analytics purposes.

**Columns:**
- `id` - UUID primary key
- `report_id` - Foreign key to `sign_off_reports`
- `exported_by` - Foreign key to `users`
- `export_format` - Format of export (pdf, docx, xlsx, csv, html, json)
- `export_type` - Type of export (download, print, email, share)
- `file_path` - Path to exported file (if saved)
- `file_size` - File size in bytes
- `file_hash` - SHA-256 hash of exported file
- `metadata` - JSONB field for export options, filters, etc.
- `created_at` - Timestamp

**Constraints:**
- `valid_export_format` - CHECK constraint for valid formats
- `valid_export_type` - CHECK constraint for valid types

**Indexes:**
- `idx_report_exports_report` - On `report_id`
- `idx_report_exports_exported_by` - On `exported_by`
- `idx_report_exports_format` - On `export_format`
- `idx_report_exports_created_at` - On `created_at`

## 🔄 Updated Existing Tables

### `sign_off_reports`
Added columns:
- `submitted_at` - Timestamp when report was submitted
- `approved_at` - Timestamp when report was approved
- `docusign_envelope_id` - Reference to DocuSign envelope

### `client_reviews`
Added columns:
- `digital_signature` - Digital signature data
- `signature_date` - Date when signature was created
- `updated_at` - Timestamp for last update

## 📊 Views Created

### 1. `reports_with_docusign`
View that joins `sign_off_reports` with `docusign_envelopes` to show DocuSign status for each report.

### 2. `reports_with_signatures`
View that shows which reports have delivery lead and client reviewer signatures, and whether they are fully signed.

### 3. `report_export_statistics`
View that provides export statistics per report (total exports, unique exporters, format breakdown, etc.).

## 🚀 How to Run the Migration

### Option 1: Using SQL File (Recommended for PostgreSQL CLI)

```bash
# Connect to your database
psql -U postgres -d flow_space

# Run the SQL file
\i backend/database/create_new_features_tables.sql
```

### Option 2: Using Node.js Migration Script

```bash
# From the backend directory
cd backend
node migrations/create_new_features_tables.js
```

### Option 3: Using Windows Batch Script

```bash
# Double-click or run from command prompt
backend\run-new-features-migration.bat
```

## ✅ Verification

After running the migration, verify the tables were created:

```sql
-- Check tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('docusign_envelopes', 'digital_signatures', 'report_exports')
ORDER BY table_name;

-- Check indexes
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('docusign_envelopes', 'digital_signatures', 'report_exports')
ORDER BY tablename, indexname;

-- Check views
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public' 
  AND table_name IN ('reports_with_docusign', 'reports_with_signatures', 'report_export_statistics')
ORDER BY table_name;
```

## 🔍 Example Queries

### Get all reports with DocuSign status
```sql
SELECT * FROM reports_with_docusign WHERE status = 'submitted';
```

### Get reports that need signatures
```sql
SELECT * FROM reports_with_signatures WHERE fully_signed = FALSE;
```

### Get export statistics for a report
```sql
SELECT * FROM report_export_statistics WHERE report_id = 'your-report-id';
```

### Get all DocuSign envelopes for a user
```sql
SELECT * FROM docusign_envelopes 
WHERE created_by = 'user-id' 
ORDER BY created_at DESC;
```

### Get all digital signatures for a report
```sql
SELECT 
  ds.*,
  u.name as signer_name,
  u.email as signer_email
FROM digital_signatures ds
JOIN users u ON ds.signer_id = u.id
WHERE ds.report_id = 'report-id'
ORDER BY ds.signed_at;
```

## 📝 Notes

- All tables use UUID primary keys for better scalability
- Foreign key constraints ensure data integrity
- Indexes are optimized for common query patterns
- JSONB fields allow flexible metadata storage
- Triggers automatically update `updated_at` timestamps
- Views provide convenient querying interfaces

## 🔒 Security Considerations

- Digital signatures are stored as base64-encoded data
- Signature hashes allow verification without exposing full signature data
- IP addresses and user agents are stored for audit purposes
- File hashes allow verification of exported file integrity

## 🐛 Troubleshooting

If you encounter errors:

1. **Table already exists**: The migration uses `CREATE TABLE IF NOT EXISTS`, so it's safe to run multiple times
2. **Column already exists**: The migration checks for existing columns before adding them
3. **Foreign key errors**: Ensure `sign_off_reports` and `users` tables exist first
4. **Permission errors**: Ensure your database user has CREATE TABLE and CREATE INDEX permissions

## 📚 Related Files

- `backend/database/create_new_features_tables.sql` - SQL migration file
- `backend/migrations/create_new_features_tables.js` - Node.js migration script
- `backend/run-new-features-migration.bat` - Windows batch script
- `lib/services/docusign_service.dart` - DocuSign integration service
- `lib/services/report_export_service.dart` - Report export service

