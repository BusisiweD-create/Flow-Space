const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
const dbConfig = require('./database-config');

// database-config.js exports the selected config directly
console.log(`\n🔧 Running deliverables table migration...`);
console.log(`📋 Database: ${dbConfig.database} @ ${dbConfig.host}\n`);

const pool = new Pool(dbConfig);

async function runMigration() {
  const client = await pool.connect();
  
  try {
    console.log('📖 Reading SQL migration file...');
    const sqlFile = path.join(__dirname, 'database', 'fix_deliverables_table.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    console.log('🚀 Executing SQL migration...\n');
    
    // Execute the SQL
    await client.query(sql);
    
    console.log('\n✅ Migration completed successfully!');
    console.log('📋 The deliverables table now has all required columns');
    console.log('\n💡 You can now try creating deliverables again!\n');
    
  } catch (error) {
    console.error('\n❌ Error running migration:', error.message);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    
    if (error.code === '42P01') {
      console.error('\n⚠️  The deliverables table does not exist.');
      console.error('   Please run create_reports_tables.sql first.\n');
    } else {
      console.error('\n📚 Full error:', error);
    }
    
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();

