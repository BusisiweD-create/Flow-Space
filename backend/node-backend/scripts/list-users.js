const { sequelize } = require('../src/models');
const { User } = require('../src/models');

async function listUsers() {
  try {
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Find all users
    const users = await User.findAll({
      attributes: ['id', 'email', 'first_name', 'last_name', 'role', 'is_active', 'is_verified']
    });
    
    console.log('\n📋 Users in database:');
    console.log('=' .repeat(80));
    
    if (users.length === 0) {
      console.log('No users found in the database');
      return;
    }
    
    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email} (${user.first_name} ${user.last_name})`);
      console.log(`   Role: ${user.role}, Active: ${user.is_active}, Verified: ${user.is_verified}`);
      console.log(`   ID: ${user.id}`);
      console.log('-' .repeat(80));
    });
    
  } catch (error) {
    console.error('❌ Error listing users:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

// Run the script
listUsers();