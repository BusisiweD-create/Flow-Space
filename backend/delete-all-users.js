// Delete all existing users to start fresh
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function deleteAllUsers() {
  try {
    console.log('🗑️ Deleting all existing users to start fresh...\n');
    
    // First, show what users will be deleted
    const usersResult = await pool.query(`
      SELECT id, email, name, role, created_at
      FROM users 
      ORDER BY created_at DESC
    `);
    
    console.log(`📊 Found ${usersResult.rows.length} users to delete:\n`);
    
    usersResult.rows.forEach((user, index) => {
      console.log(`${index + 1}. 👤 ${user.name} (${user.email}) - ${user.role}`);
      console.log(`   📅 Created: ${new Date(user.created_at).toLocaleString()}`);
    });
    
    console.log('\n⚠️  This will permanently delete all user accounts!');
    console.log('🔄 Proceeding with deletion...\n');
    
    // Delete all users
    const deleteResult = await pool.query('DELETE FROM users');
    
    console.log(`✅ Deleted ${deleteResult.rowCount} users successfully!`);
    
    // Verify deletion
    const verifyResult = await pool.query('SELECT COUNT(*) as count FROM users');
    console.log(`🔍 Verification: ${verifyResult.rows[0].count} users remaining in database`);
    
    console.log('\n🎉 Database is now clean!');
    console.log('💡 You can now create a new account through your Flutter app');
    console.log('📱 The registration process will work normally');
    
  } catch (error) {
    console.error('❌ Error deleting users:', error.message);
  } finally {
    await pool.end();
  }
}

deleteAllUsers();
