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
    console.log('Updating roles for Thandeka Mazibuko and Bernice Nyabela...');
    
    // User IDs and their correct roles
    const usersToUpdate = [
      { 
        id: 'e83003e7-e75f-4442-bc93-48befe6083e1', 
        name: 'Thandeka Mazibuko', 
        currentRole: 'deliveryLead', 
        correctRole: 'clientReviewer',
        correctRoleId: 3
      },
      { 
        id: 'cd28eaf5-ca26-4a27-b2b7-08ca61828e37', 
        name: 'Bernice Nyabela', 
        currentRole: 'teamMember', 
        correctRole: 'deliveryLead',
        correctRoleId: 2
      }
    ];
    
    for (const user of usersToUpdate) {
      console.log(`\nUpdating ${user.name}...`);
      console.log(`Current role: ${user.currentRole} (ID: ${user.currentRole === 'teamMember' ? 1 : user.currentRole === 'deliveryLead' ? 2 : user.currentRole === 'clientReviewer' ? 3 : 4})`);
      console.log(`Correct role: ${user.correctRole} (ID: ${user.correctRoleId})`);
      
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