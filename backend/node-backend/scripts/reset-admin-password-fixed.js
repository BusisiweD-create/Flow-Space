const { sequelize } = require('../src/models');
const { User } = require('../src/models');
const { getPasswordHash } = require('../src/utils/authUtils');

async function resetAdminPassword() {
  try {
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Find the admin user with correct role format
    const adminUser = await User.findOne({ 
      where: { 
        email: 'admin@flowspace.com'
      } 
    });
    
    if (!adminUser) {
      console.log('❌ Admin user not found');
      return;
    }
    
    // Reset password
    const newPassword = 'Admin123!';
    const hashedPassword = await getPasswordHash(newPassword);
    
    await adminUser.update({
      hashed_password: hashedPassword,
      is_active: true,
      is_verified: true,
      role: 'system_admin' // Ensure correct role format
    });
    
    console.log('✅ Admin password reset successfully:');
    console.log('   Email: admin@flowspace.com');
    console.log('   New Password: Admin123!');
    console.log('   Role: system_admin');
    console.log('   User ID:', adminUser.id);
    
  } catch (error) {
    console.error('❌ Error resetting admin password:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

// Run the script
resetAdminPassword();