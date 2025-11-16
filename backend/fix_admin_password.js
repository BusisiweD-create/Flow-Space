const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const dbConfig = require('./database-config');

async function fixAdminPassword() {
  const pool = new Pool(dbConfig);
  
  try {
    console.log('Fixing admin@flowspace.com password...');
    
    // Hash the correct password
    const correctPassword = 'admin123';
    const hashedPassword = await bcrypt.hash(correctPassword, 10);
    
    console.log('New password hash:', hashedPassword);
    
    // Update the user's password
    const result = await pool.query(
      'UPDATE users SET hashed_password = $1 WHERE email = $2 RETURNING id, email',
      [hashedPassword, 'admin@flowspace.com']
    );
    
    if (result.rows.length === 0) {
      console.log('❌ admin@flowspace.com not found in database');
      return;
    }
    
    const user = result.rows[0];
    console.log('✅ Password updated for:', user.email);
    console.log('User ID:', user.id);
    
  } catch (error) {
    console.error('Error fixing admin password:', error);
  } finally {
    await pool.end();
  }
}

fixAdminPassword();