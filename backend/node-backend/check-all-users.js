require('dotenv').config({path: '../.env'});
const { sequelize, User } = require('./src/models');

async function checkUsers() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');
    
    const users = await User.findAll({
      attributes: ['id', 'email', 'first_name', 'last_name', 'role', 'is_active', 'password_hash']
    });
    
    console.log(`📊 Found ${users.length} users:`);
    users.forEach(user => {
      console.log(`- ${user.email} (${user.first_name} ${user.last_name}) - Active: ${user.is_active} - Has Password: ${!!user.password_hash}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await sequelize.close();
  }
}

checkUsers();
