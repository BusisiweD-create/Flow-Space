require('dotenv').config({path: '../.env'});
const { sequelize, User } = require('./src/models');
const bcrypt = require('bcryptjs');

async function updatePassword() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');
    
    const testUser = await User.findOne({
      where: { email: 'sipho.masango2407@gmail.com' }
    });
    
    if (testUser) {
      console.log('✅ Found user:', testUser.email);
      console.log('🔑 Current password hash exists:', !!testUser.hashed_password);
      
      // Update password with correct hash
      const hashedPassword = await bcrypt.hash('@Password2', 12);
      await testUser.update({ 
        hashed_password: hashedPassword,
        is_active: true 
      });
      
      console.log('✅ Password updated successfully');
    } else {
      console.log('❌ User not found');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await sequelize.close();
  }
}

updatePassword();
