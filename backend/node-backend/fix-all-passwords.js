require('dotenv').config({path: '../.env'});
const { sequelize, User } = require('./src/models');
const bcrypt = require('bcryptjs');

async function fixAllPasswords() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');
    
    const users = await User.findAll();
    const hashedPassword = await bcrypt.hash('@Password2', 12);
    
    for (const user of users) {
      if (!user.password_hash) {
        await user.update({ 
          password_hash: hashedPassword,
          is_active: true 
        });
        console.log(`✅ Fixed password for: ${user.email}`);
      }
    }
    
    console.log('🎉 All user passwords have been fixed!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await sequelize.close();
  }
}

fixAllPasswords();
