// Production Epics Migration Script for Render
// Run this script on the Render server to create missing epics tables

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

async function runProductionEpicsMigration() {
  try {
    console.log('🚀 Starting production epics migration...');
    
    // Read the migration SQL file
    const fs = require('fs');
    const path = require('path');
    const sqlFilePath = path.join(__dirname, 'production-epics-migration.sql');
    
    if (!fs.existsSync(sqlFilePath)) {
      throw new Error(`Migration file not found: ${sqlFilePath}`);
    }
    
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    console.log(`📄 Loaded migration file: ${sqlFilePath}`);
    
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
        const result = await pool.query(statement);
        
        if (result.rows && result.rows.length > 0) {
          console.log(`✅ Statement ${i + 1} completed successfully`);
          result.rows.forEach(row => {
            console.log(`   📋 ${JSON.stringify(row)}`);
          });
        } else {
          console.log(`✅ Statement ${i + 1} completed successfully`);
        }
      } catch (error) {
        // Some errors are okay (like "already exists")
        if (error.message.includes('already exists') || 
            error.message.includes('duplicate')) {
          console.log(`⚠️  Statement ${i + 1}: ${error.message} (skipping)`);
        } else {
          console.error(`❌ Error in statement ${i + 1}:`, error.message);
          console.error('Statement:', statement.substring(0, 200) + '...');
          throw error;
        }
      }
    }
    
    console.log('\n✅ Production epics migration completed successfully!');
    console.log('\n📊 Verifying tables...');
    
    // Verify tables exist
    const tableCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('epics', 'sprint_epics', 'deliverable_epics')
      ORDER BY table_name
    `);
    
    console.log('\n✅ Created/verified tables:');
    tableCheck.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });
    
    // Test epics table functionality
    console.log('\n🔍 Testing epics table functionality...');
    const testResult = await pool.query('SELECT COUNT(*) as count FROM epics');
    console.log(`✅ Epics table is accessible. Current record count: ${testResult.rows[0].count}`);
    
    console.log('\n🎉 Production epics migration is complete!');
    console.log('📡 The epics API endpoints should now work correctly.');
    
  } catch (error) {
    console.error('❌ Production migration failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run the migration
runProductionEpicsMigration();
