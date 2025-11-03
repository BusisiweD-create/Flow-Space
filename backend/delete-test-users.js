const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function deleteTestUsers() {
  try {
    console.log('🗑️ Deleting test users...');
    
    // Delete users by email
    const emailsToDelete = [
      'kasikash34@gmail.com',
      'mabotsaboitumelo5@gmail.com'
    ];
    
    for (const email of emailsToDelete) {
      const result = await pool.query(
        'DELETE FROM users WHERE email = $1',
        [email]
      );
      
      if (result.rowCount > 0) {
        console.log(`✅ Deleted user: ${email}`);
      } else {
        console.log(`ℹ️ User not found: ${email}`);
      }
    }
    
    console.log('🎉 Test users deletion completed!');
  } catch (error) {
    console.error('❌ Error deleting test users:', error);
  } finally {
    await pool.end();
  }
}

deleteTestUsers();
