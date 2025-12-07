const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function deleteUser() {
  try {
    const userEmail = 'Tshepo.Madiba@khonology.com';
    
    console.log('Deleting user:', userEmail);
    
    // First, let's get the user details for confirmation
    const userResult = await pool.query(
      'SELECT id, email, first_name, last_name, role FROM users WHERE email = $1',
      [userEmail]
    );
    
    if (userResult.rows.length === 0) {
      console.log('❌ User not found');
      return;
    }
    
    const user = userResult.rows[0];
    console.log('User found:');
    console.log('ID:', user.id);
    console.log('Email:', user.email);
    console.log('First Name:', user.first_name);
    console.log('Last Name:', user.last_name);
    console.log('Role:', user.role);
    
    // Delete the user
    const deleteResult = await pool.query(
      'DELETE FROM users WHERE email = $1 RETURNING id',
      [userEmail]
    );
    
    if (deleteResult.rows.length > 0) {
      console.log('✅ User deleted successfully!');
      console.log('Deleted user ID:', deleteResult.rows[0].id);
    } else {
      console.log('❌ User deletion failed');
    }
    
  } catch (error) {
    console.error('Error deleting user:', error.message);
  } finally {
    await pool.end();
  }
}

deleteUser();