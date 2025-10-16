const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function findThabsUser() {
  try {
    console.log('Searching for Thabs Nkabinde in database...');
    
    // Search for the user by name or email
    const result = await pool.query(`
      SELECT id, email, first_name, last_name, role 
      FROM users 
      WHERE email LIKE '%nkabinde%' 
         OR email LIKE '%thabang%' 
         OR first_name LIKE '%Thabang%' 
         OR last_name LIKE '%Nkabinde%'
    `);
    
    if (result.rows.length > 0) {
      console.log('✅ Found user(s):');
      result.rows.forEach((user, index) => {
        console.log(`\nUser ${index + 1}:`);
        console.log('ID:', user.id);
        console.log('Email:', user.email);
        console.log('First Name:', user.first_name);
        console.log('Last Name:', user.last_name);
        console.log('Role:', user.role);
      });
    } else {
      console.log('❌ No users found with name containing "Thabang" or "Nkabinde"');
    }
    
  } catch (error) {
    console.error('Error searching for user:', error.message);
  } finally {
    await pool.end();
  }
}

findThabsUser();