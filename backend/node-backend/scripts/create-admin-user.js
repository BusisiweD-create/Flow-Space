const { sequelize } = require('../src/models');
const { User } = require('../src/models');
const { getPasswordHash } = require('../src/utils/authUtils');

async function createAdminUser() {
  try {
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Check if admin user already exists
    const existingAdmin = await User.findOne({ 
      where: { 
        email: 'admin@flowspace.com',
        role: 'system_admin' 
      } 
    });
    
    if (existingAdmin) {
      console.log('ℹ️  Admin user already exists:', existingAdmin.email);
      return;
    }
    
    // Create admin user
    const adminPassword = await getPasswordHash('Admin123!');
    const adminUser = await User.create({
      email: 'admin@flowspace.com',
      hashed_password: adminPassword,
      first_name: 'System',
      last_name: 'Administrator',
      company: 'FlowSpace',
      role: 'system_admin',
      is_active: true,
      is_verified: true
    });
    
    console.log('✅ Admin user created successfully:');
    console.log('   Email: admin@flowspace.com');
    console.log('   Password: Admin123!');
    console.log('   Role: system_admin');
    console.log('   User ID:', adminUser.id);
    
  } catch (error) {
    console.error('❌ Error creating admin user:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

// Run the script
createAdminUser();