const { Pool } = require('pg');
const dbConfig = require('./database-config');

async function checkAdminPassword() {
  const pool = new Pool(dbConfig);
  
  try {
    console.log('Checking admin@flowspace.com password hash...');
    
    const result = await pool.query(
      'SELECT id, email, hashed_password FROM users WHERE email = $1',
      ['admin@flowspace.com']
    );
    
    if (result.rows.length === 0) {
      console.log('❌ admin@flowspace.com not found in database');
      return;
    }
    
    const user = result.rows[0];
    console.log('✅ User found:', user.email);
    console.log('User ID:', user.id);
    console.log('Password hash:', user.hashed_password);
    console.log('Hash length:', user.hashed_password?.length || 'null');
    
  } catch (error) {
    console.error('Error checking admin password:', error);
  } finally {
    await pool.end();
  }
}

checkAdminPassword();