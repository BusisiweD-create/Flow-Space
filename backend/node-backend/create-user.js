require('dotenv').config({path: '../.env'});
const { sequelize, User } = require('./src/models');
const bcrypt = require('bcryptjs');

async function createTestUser() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');
    
    const users = await User.findAll();
    console.log(`📊 Found ${users.length} users`);
    
    if (users.length === 0) {
      console.log('Creating test user...');
      const hashedPassword = await bcrypt.hash('@Password2', 12);
      const newUser = await User.create({
        email: 'sipho.masango2407@gmail.com',
        hashed_password: hashedPassword,
        first_name: 'Sipho',
        last_name: 'Masango',
        role: 'user',
        is_active: true
      });
      console.log('✅ Test user created');
    } else {
      console.log('Users already exist');
      const testUser = await User.findOne({
        where: { email: 'sipho.masango2407@gmail.com' }
      });
      if (testUser) {
        console.log('✅ Found test user:', testUser.email);
      } else {
        console.log('❌ Test user not found, creating...');
        const hashedPassword = await bcrypt.hash('@Password2', 12);
        const newUser = await User.create({
          email: 'sipho.masango2407@gmail.com',
          hashed_password: hashedPassword,
          first_name: 'Sipho',
          last_name: 'Masango',
          role: 'user',
          is_active: true
        });
        console.log('✅ Test user created');
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await sequelize.close();
  }
}

createTestUser();
