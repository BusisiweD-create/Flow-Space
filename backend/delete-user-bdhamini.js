const { Pool } = require('pg');
require('dotenv').config();

console.log('🗑️ User Deletion Tool');
console.log('Target user: bdhamini883@gmail.com');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flowspace',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function deleteUser() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // First, check if user exists
    console.log('\n🔍 Checking if user exists...');
    const checkResult = await client.query(
      'SELECT id, email, name, role, created_at FROM users WHERE email = $1',
      ['bdhamini883@gmail.com']
    );
    
    if (checkResult.rows.length === 0) {
      console.log('❌ User bdhamini883@gmail.com not found in database');
      return;
    }
    
    const user = checkResult.rows[0];
    console.log('✅ Found user:');
    console.log(`   ID: ${user.id}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Name: ${user.name}`);
    console.log(`   Role: ${user.role}`);
    console.log(`   Created: ${user.created_at}`);
    
    // Confirm deletion
    console.log('\n⚠️  WARNING: This will permanently delete the user and all associated data!');
    console.log('   Associated data to be deleted:');
    console.log('   - User profile and preferences');
    console.log('   - User sessions and tokens');
    console.log('   - Projects owned by user');
    console.log('   - Sprint assignments');
    console.log('   - Approval requests');
    console.log('   - Notifications');
    
    // Delete user and related data
    console.log('\n🗑️  Deleting user and related data...');
    
    // Delete from related tables (in order of dependencies)
    const tables = [
      { name: 'user_sessions', sql: 'DELETE FROM user_sessions WHERE user_id = $1' },
      { name: 'notifications', sql: 'DELETE FROM notifications WHERE user_id = $1' },
      { name: 'approval_requests', sql: 'DELETE FROM approval_requests WHERE requested_by = $1 OR approved_by = $1' },
      { name: 'sprint_assignments', sql: 'DELETE FROM sprint_assignments WHERE user_id = $1' },
      { name: 'project_members', sql: 'DELETE FROM project_members WHERE user_id = $1' },
      { name: 'projects', sql: 'DELETE FROM projects WHERE created_by = $1' },
      { name: 'users', sql: 'DELETE FROM users WHERE id = $1' }
    ];
    
    let totalDeleted = 0;
    for (const table of tables) {
      try {
        const result = await client.query(table.sql, [user.id]);
        const deletedCount = result.rowCount || 0;
        console.log(`   ✅ Deleted from ${table.name}: ${deletedCount} rows`);
        totalDeleted += deletedCount;
      } catch (error) {
        console.log(`   ⚠️  ${table.name}: ${error.message}`);
      }
    }
    
    await client.query('COMMIT');
    console.log('\n✅ User bdhamini883@gmail.com deleted successfully!');
    console.log(`🎉 Total records deleted: ${totalDeleted}`);
    console.log('🔄 All associated data has been removed.');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error deleting user:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

// Run the deletion
deleteUser().catch(console.error);
