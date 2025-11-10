const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres'
});

async function checkColumns() {
  try {
    console.log('🔍 Checking database columns for users table...');
    
    // Check what password-related columns exist
    const result = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND (column_name = 'hashed_password' OR column_name = 'password_hash')
    `);
    
    console.log('Found password columns:', result.rows.map(r => r.column_name));
    
    // Check all columns to see what's actually there
    const allColumns = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users'
      ORDER BY column_name
    `);
    
    console.log('All user table columns:');
    allColumns.rows.forEach(row => {
      console.log('  -', row.column_name);
    });
    
    // Check what's actually in the database for our user
    const userResult = await pool.query(`
      SELECT * FROM users WHERE email = 'Thabang.Nkabinde@khonology.com'
    `);
    
    if (userResult.rows.length > 0) {
      const user = userResult.rows[0];
      console.log('\n🔍 User data for Thabang.Nkabinde@khonology.com:');
      console.log('ID:', user.id);
      console.log('Email:', user.email);
      console.log('Password field present:', 'hashed_password' in user ? user.hashed_password : 'password_hash' in user ? user.password_hash : 'NOT FOUND');
      console.log('Is active:', user.is_active);
      console.log('Role:', user.role);
    } else {
      console.log('❌ User not found');
    }
    
  } catch (error) {
    console.error('❌ Error checking columns:', error);
  } finally {
    await pool.end();
  }
}

checkColumns();