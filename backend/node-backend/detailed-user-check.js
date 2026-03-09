require('dotenv').config({ path: '../.env' });
const { sequelize } = require('./src/config/database');
const { User } = require('./src/models');

async function detailedUserCheck() {
  try {
    await sequelize.authenticate();
    console.log('Database connected successfully');
    
    const user = await User.findOne({ where: { email: 'tshabalalasipho988@gmail.com' } });
    
    if (user) {
      console.log('User found:');
      console.log('ID:', user.id);
      console.log('Email:', user.email);
      console.log('Role:', user.role);
      console.log('Active:', user.is_active);
      console.log('Raw user data keys:', Object.keys(user.dataValues));
      console.log('Raw user data:', JSON.stringify(user.dataValues, null, 2));
      
      // Check both possible field names
      console.log('hashed_password field:', !!user.dataValues.hashed_password);
      console.log('password_hash field:', !!user.dataValues.password_hash);
      
      if (user.dataValues.hashed_password) {
        console.log('hashed_password length:', user.dataValues.hashed_password.length);
        console.log('hashed_password format:', user.dataValues.hashed_password.substring(0, 10) + '...');
      }
      
      if (user.dataValues.password_hash) {
        console.log('password_hash length:', user.dataValues.password_hash.length);
        console.log('password_hash format:', user.dataValues.password_hash.substring(0, 10) + '...');
      }
    } else {
      console.log('User NOT found in database');
    }
    
    await sequelize.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

detailedUserCheck();
