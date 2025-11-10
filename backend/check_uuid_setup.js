const { Pool } = require('pg');
const pool = new Pool(require('./database-config.js'));

async function checkUUIDSetup() {
  try {
    // Check if uuid-ossp extension is available
    const extensionCheck = await pool.query(`
      SELECT installed_version FROM pg_available_extensions 
      WHERE name = 'uuid-ossp'
    `);
    
    console.log('UUID-OSSP extension available:', extensionCheck.rows.length > 0);
    
    if (extensionCheck.rows.length > 0) {
      console.log('Installed version:', extensionCheck.rows[0].installed_version || 'Not installed');
    }
    
    // Check the default value for id column
    const defaultCheck = await pool.query(`
      SELECT column_default 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'id'
    `);
    
    if (defaultCheck.rows.length > 0) {
      console.log('ID column default:', defaultCheck.rows[0].column_default || 'No default');
    }
    
    pool.end();
  } catch (error) {
    console.error('Error checking UUID setup:', error.message);
    pool.end();
  }
}

checkUUIDSetup();