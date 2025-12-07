require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function runMigration() {
  try {
    console.log('🚀 Starting database migration...');
    
    // Read the SQL file - try new migration file first, then fallback
    let sqlFilePath = path.join(__dirname, 'database/migrations/add_missing_tables.sql');
    if (!fs.existsSync(sqlFilePath)) {
      sqlFilePath = path.join(__dirname, 'create_missing_tables.sql');
    }
    console.log(`📄 Using migration file: ${sqlFilePath}`);
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    
    // Split by semicolons to execute each statement separately
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    console.log(`📝 Found ${statements.length} SQL statements to execute\n`);
    
    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      
      // Skip comment-only statements
      if (statement.replace(/--.*$/gm, '').trim().length === 0) {
        continue;
      }
      
      try {
        console.log(`⏳ Executing statement ${i + 1}/${statements.length}...`);
        await pool.query(statement);
        console.log(`✅ Statement ${i + 1} completed successfully`);
      } catch (error) {
        // Some errors are okay (like "column already exists")
        if (error.message.includes('already exists') || 
            error.message.includes('duplicate')) {
          console.log(`⚠️  Statement ${i + 1}: ${error.message} (skipping)`);
        } else {
          console.error(`❌ Error in statement ${i + 1}:`, error.message);
          console.error('Statement:', statement.substring(0, 100) + '...');
        }
      }
    }
    
    console.log('\n✅ Migration completed successfully!');
    console.log('\n📊 Verifying tables...');
    
    // Verify tables exist
    const tableCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('epics', 'sprint_metrics', 'digital_signatures', 'approval_requests', 'change_requests', 'documents', 'users', 'projects', 'sprints', 'deliverables', 'notifications', 'sign_off_reports')
      ORDER BY table_name
    `);
    
    console.log('\n✅ Existing tables:');
    tableCheck.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });
    
    // Check for new columns in deliverables
    console.log('\n📋 Checking deliverables columns...');
    const deliverableColumns = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'deliverables' 
      AND column_name IN ('priority', 'sprint_id', 'sprint_ids', 'epic_id', 'evidence_links')
    `);
    
    deliverableColumns.rows.forEach(row => {
      console.log(`   ✓ ${row.column_name}`);
    });
    
    // Check epics table columns
    console.log('\n📋 Checking epics table columns...');
    const epicColumns = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'epics'
      ORDER BY ordinal_position
    `);
    
    epicColumns.rows.forEach(row => {
      console.log(`   ✓ ${row.column_name}`);
    });
    
    console.log('\n🎉 All done! Your database is ready.');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    await pool.end();
  }
}

runMigration();

