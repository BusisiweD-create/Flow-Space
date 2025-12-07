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
    // Thabs Nkabinde user IDs
    const userIds = [
      'c5b5fe8f-e387-474b-9d5a-18485d835490', // Thabang.Nkabinde@khonology.com
      '2b9adcb5-e6da-4559-be5d-cf00f262efea'  // nkabindethabang77@gmail.com
    ];
    const newRole = 'systemAdmin';
    
    console.log('Updating user roles...');
    console.log('New Role:', newRole);
    console.log('Updating', userIds.length, 'users');
    
    // Update all Thabs Nkabinde accounts
    for (const userId of userIds) {
      const result = await pool.query(
        'UPDATE users SET role = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, email, first_name, last_name, role',
        [newRole, userId]
      );
    
      if (result.rows.length > 0) {
        const updatedUser = result.rows[0];
        console.log('✅ User role updated successfully:');
        console.log('User ID:', updatedUser.id);
        console.log('Email:', updatedUser.email);
        console.log('Name:', updatedUser.first_name, updatedUser.last_name);
        console.log('New Role:', updatedUser.role);
        console.log('---');
      } else {
        console.log('❌ User not found with ID:', userId);
      }
    }
    
  } catch (error) {
    console.error('Error updating user role:', error.message);
  } finally {
    await pool.end();
  }
}

updateUserRole();