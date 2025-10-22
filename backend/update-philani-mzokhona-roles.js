const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function updateUserRoles() {
  try {
    console.log('Updating roles for Philani Sokhela and Mzokhona Khumalo...');
    
    // User IDs and their correct roles
    const usersToUpdate = [
      { id: 'd810bc46-dad9-45b8-8c0d-2ed33ea1f522', name: 'Philani Sokhela', currentRole: 'deliveryLead', correctRole: 'scrumMaster' },
      { id: '9756387c-8a8f-4117-b8fd-68fc98bf76eb', name: 'Mzokhona Khumalo', currentRole: 'teamMember', correctRole: 'qaEngineer' }
    ];
    
    for (const user of usersToUpdate) {
      console.log(`\nUpdating ${user.name}...`);
      console.log(`Current role: ${user.currentRole}`);
      console.log(`Correct role: ${user.correctRole}`);
      
      // Update the user role
      const result = await pool.query(
        'UPDATE users SET role = $1 WHERE id = $2 RETURNING id, email, first_name, last_name, role',
        [user.correctRole, user.id]
      );
      
      if (result.rows.length > 0) {
        const updatedUser = result.rows[0];
        console.log(`✅ Successfully updated ${user.name}:`);
        console.log(`   Email: ${updatedUser.email}`);
        console.log(`   New Role: ${updatedUser.role}`);
      } else {
        console.log(`❌ User ${user.name} not found`);
      }
      
      console.log('---');
    }
    
    console.log('✅ Role updates completed!');
    
  } catch (error) {
    console.error('Error updating user roles:', error.message);
  } finally {
    await pool.end();
  }
}

updateUserRoles();