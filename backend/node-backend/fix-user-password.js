require('dotenv').config({ path: '../.env' });
const { sequelize } = require('./src/config/database');
const { User } = require('./src/models');
const bcrypt = require('bcrypt');

async function fixUserPassword() {
  try {
    await sequelize.authenticate();
    console.log('Database connected successfully');
    
    const user = await User.findOne({ where: { email: 'tshabalalasipho988@gmail.com' } });
    
    if (user) {
      console.log('User found:', user.email);
      console.log('Current password hash exists:', !!user.password_hash);
      
      // Hash the password
      const hashedPassword = await bcrypt.hash('@Password2', 10);
      console.log('Generated password hash length:', hashedPassword.length);
      
      // Update the user with the hashed password
      await user.update({ 
        password_hash: hashedPassword,
        is_active: true 
      });
      
      console.log('✅ Password updated successfully for:', user.email);
      console.log('✅ User is now active');
    } else {
      console.log('User NOT found in database');
    }
    
    await sequelize.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

fixUserPassword();
