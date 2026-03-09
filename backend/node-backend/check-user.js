require('dotenv').config({ path: '../.env' });
const { sequelize } = require('./src/config/database');
const { User } = require('./src/models');

async function checkUser() {
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
      console.log('Password hash exists:', !!user.password_hash);
      console.log('Password hash length:', user.password_hash ? user.password_hash.length : 0);
      console.log('Password hash format:', user.password_hash ? user.password_hash.substring(0, 10) + '...' : 'none');
    } else {
      console.log('User NOT found in database');
    }
    
    await sequelize.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkUser();
