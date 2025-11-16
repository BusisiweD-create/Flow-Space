const { Pool } = require('pg');

// Use the same database configuration as the application
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function updateAdminRole() {
  try {
    console.log('Updating admin user role from "systemAdmin" to "admin"...');
    
    const result = await pool.query(
      'UPDATE users SET role = $1, updated_at = NOW() WHERE email = $2 RETURNING id, email, role',
      ['admin', 'admin@flowspace.com']
    );
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('✅ Admin user role updated successfully:');
      console.log(`   ID: ${user.id}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   New Role: ${user.role}`);
    } else {
      console.log('⚠️  No user found with email admin@flowspace.com');
    }
    
  } catch (error) {
    console.error('❌ Error updating admin role:', error.message);
  } finally {
    await pool.end();
  }
}

updateAdminRole();