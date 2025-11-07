const { sequelize, User } = require('./src/models');

async function checkAndCreateUsers() {
  try {
    // Check if users table exists and has data
    const users = await User.findAll();
    
    console.log(`Found ${users.length} users in the database:`);
    users.forEach(user => {
      console.log(`- ${user.email} (${user.first_name} ${user.last_name})`);
    });
    
    // If no users, create a test user
    if (users.length === 0) {
      console.log('No users found. Creating test user...');
      
      const testUser = await User.create({
        email: 'test@example.com',
        hashed_password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        first_name: 'Test',
        last_name: 'User',
        company: 'Test Company',
        role: 'admin',
        is_active: true,
        is_verified: true
      });
      
      console.log('✅ Test user created successfully:');
      console.log(`- Email: ${testUser.email}`);
      console.log(`- Password: password`);
      console.log(`- Name: ${testUser.first_name} ${testUser.last_name}`);
    }
    
  } catch (error) {
    console.error('Error checking users:', error);
  } finally {
    await sequelize.close();
  }
}

checkAndCreateUsers();