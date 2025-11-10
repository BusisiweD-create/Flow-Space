const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function findUsers() {
  try {
    console.log('Searching for Thandeka and Bernice users...');
    
    // Search for users with names containing Thandeka or Bernice
    const result = await pool.query(
      `SELECT id, email, first_name, last_name, role, is_active, created_at 
       FROM users 
       WHERE first_name ILIKE $1 OR first_name ILIKE $2 OR email ILIKE $1 OR email ILIKE $2`,
      ['%thandeka%', '%bernice%']
    );
    
    if (result.rows.length > 0) {
      console.log('Found users:');
      result.rows.forEach(user => {
        console.log(`ID: ${user.id}`);
        console.log(`Name: ${user.first_name} ${user.last_name}`);
        console.log(`Email: ${user.email}`);
        console.log(`Role: ${user.role}`);
        console.log(`Active: ${user.is_active}`);
        console.log(`Created: ${user.created_at}`);
        console.log('---');
      });
    } else {
      console.log('No users found with names containing Thandeka or Bernice');
      
      // Let's also check all users to see what's in the database
      const allUsers = await pool.query('SELECT id, email, first_name, last_name, role FROM users ORDER BY created_at DESC LIMIT 10');
      console.log('\nRecent users in database:');
      allUsers.rows.forEach(user => {
        console.log(`- ${user.first_name} ${user.last_name} (${user.email}): ${user.role}`);
      });
    }
    
  } catch (error) {
    console.error('Error searching for users:', error.message);
  } finally {
    await pool.end();
  }
}

findUsers();