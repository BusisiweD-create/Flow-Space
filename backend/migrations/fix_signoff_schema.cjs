const { Pool } = require('pg');
const dbConfig = require('../database-config.cjs');

async function run() {
  console.log('🛠️ Fixing sign_off_reports schema (adding report_title if missing)...');
  const pool = new Pool(dbConfig);
  const client = await pool.connect();

  try {
    await client.query(
      "ALTER TABLE sign_off_reports ADD COLUMN IF NOT EXISTS report_title VARCHAR(255);"
    );
    console.log('✅ sign_off_reports.report_title ensured.');
  } catch (err) {
    console.error('❌ Error fixing sign_off_reports schema:', err.message);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  run().catch(err => {
    console.error('❌ fix_signoff_schema migration failed:', err.message);
    process.exit(1);
  });
}

module.exports = { run };
