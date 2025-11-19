// Automated script to create reports tables
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const dbConfig = require('./database-config');

async function setupReportsTables() {
  console.log('🗄️  Setting up reports tables...\n');
  
  const pool = new Pool(dbConfig);
  
  try {
    // Read the SQL file
    const sqlPath = path.join(__dirname, 'database', 'create_reports_tables.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Execute the SQL
    console.log('📝 Executing SQL script...');
    await pool.query(sql);
    
    console.log('\n✅ Reports tables created successfully!\n');
    console.log('📊 Tables created:');
    console.log('   - sign_off_reports');
    console.log('   - client_reviews');
    console.log('   - deliverables');
    console.log('\n🎯 Sample deliverables added for testing\n');
    
    // Verify tables exist
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('sign_off_reports', 'client_reviews', 'deliverables')
      ORDER BY table_name
    `);
    
    console.log('✓ Verified tables:');
    result.rows.forEach(row => console.log(`   ✓ ${row.table_name}`));
    
    console.log('\n🎉 Setup complete! You can now create reports in the app.\n');
    
  } catch (error) {
    console.error('\n❌ Error setting up tables:', error.message);
    if (error.code === '42P07') {
      console.log('\n⚠️  Tables already exist. This is fine!\n');
    } else {
      console.error('\nFull error:', error);
      process.exit(1);
    }
  } finally {
    await pool.end();
  }
}

// Run the setup
setupReportsTables();

