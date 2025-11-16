const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function checkRoles() {
  try {
    console.log('Checking user roles mapping...');
    
    // Check if there's a user_roles table
    const rolesResult = await pool.query('SELECT * FROM user_roles ORDER BY id');
    
    if (rolesResult.rows.length > 0) {
      console.log('User roles mapping:');
      rolesResult.rows.forEach(role => {
        console.log(`ID: ${role.id}, Name: ${role.name}, Display: ${role.display_name}`);
      });
    } else {
      console.log('No user_roles table found, checking users table for role values...');
      
      // Check distinct role values in users table
      const distinctRoles = await pool.query('SELECT DISTINCT role FROM users ORDER BY role');
      console.log('Distinct role values in users table:');
      distinctRoles.rows.forEach(row => {
        console.log(`- ${row.role}`);
      });
    }
    
  } catch (error) {
    console.error('Error checking roles:', error.message);
  } finally {
    await pool.end();
  }
}

checkRoles();