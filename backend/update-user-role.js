const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function updateUserRole() {
  try {
    const userId = '265ad069-38e4-45c0-9a77-138722a8493e';
    const newRole = 'clientReviewer';
    
    console.log('Updating user role...');
    console.log('User ID:', userId);
    console.log('New Role:', newRole);
    
    // Update the user role
    const result = await pool.query(
      'UPDATE users SET role = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, email, first_name, last_name, role',
      [newRole, userId]
    );
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('✅ User role updated successfully!');
      console.log('Updated User:');
      console.log('ID:', user.id);
      console.log('Email:', user.email);
      console.log('First Name:', user.first_name);
      console.log('Last Name:', user.last_name);
      console.log('New Role:', user.role);
    } else {
      console.log('❌ User not found');
    }
    
  } catch (error) {
    console.error('Error updating user role:', error.message);
  } finally {
    await pool.end();
  }
}

updateUserRole();