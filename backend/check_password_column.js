const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres',
});

async function checkPasswordColumn() {
  try {
    console.log('🔍 Checking password column name in users table...');
    
    // Check if password_hash column exists
    const passwordHashResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'password_hash'
    `);
    
    // Check if hashed_password column exists  
    const hashedPasswordResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'hashed_password'
    `);
    
    console.log('password_hash column exists:', passwordHashResult.rows.length > 0);
    console.log('hashed_password column exists:', hashedPasswordResult.rows.length > 0);
    
    if (passwordHashResult.rows.length > 0) {
      console.log('✅ Database uses password_hash column');
    } else if (hashedPasswordResult.rows.length > 0) {
      console.log('✅ Database uses hashed_password column');
    } else {
      console.log('❌ Neither password column found');
    }
    
  } catch (error) {
    console.error('❌ Error checking columns:', error.message);
  } finally {
    await pool.end();
  }
}

checkPasswordColumn();