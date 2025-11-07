const { sequelize } = require('./src/config/database');

async function checkUsers() {
  try {
    console.log('📊 Checking users in database...');
    
    // Test database connection first
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Query all users
    const [users, metadata] = await sequelize.query('SELECT * FROM users');
    
    console.log(`\n📋 Found ${users.length} user(s):`);
    console.log('='.repeat(80));
    
    users.forEach((user, index) => {
      console.log(`\n👤 User ${index + 1}:`);
      console.log(`   ID: ${user.id}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   First Name: ${user.first_name || 'N/A'}`);
      console.log(`   Last Name: ${user.last_name || 'N/A'}`);
      console.log(`   Role: ${user.role || 'N/A'}`);
      console.log(`   Created: ${user.created_at || 'N/A'}`);
      console.log(`   Updated: ${user.updated_at || 'N/A'}`);
    });
    
    console.log('\n' + '='.repeat(80));
    
  } catch (error) {
    console.error('❌ Error checking users:', error.message);
    
    // If users table doesn't exist, show the error
    if (error.message.includes('no such table')) {
      console.log('\n💡 The users table does not exist yet.');
      console.log('   Run the database setup script first.');
    }
  } finally {
    await sequelize.close();
  }
}

// Run the function
checkUsers();