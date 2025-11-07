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
    console.log('Searching for Philani Sokhela and Mzokhona Khumalo in database...');
    
    // Search for the users by name
    const result = await pool.query(`
      SELECT id, email, first_name, last_name, role 
      FROM users 
      WHERE first_name ILIKE '%philani%' 
         OR last_name ILIKE '%sokhela%' 
         OR first_name ILIKE '%mzokhona%' 
         OR last_name ILIKE '%khumalo%'
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
        console.log('---');
      });
    } else {
      console.log('❌ No users found with names Philani Sokhela or Mzokhona Khumalo');
    }
    
  } catch (error) {
    console.error('Error searching for users:', error.message);
  } finally {
    await pool.end();
  }
}

findUsers();