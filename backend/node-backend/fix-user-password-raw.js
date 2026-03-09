require('dotenv').config({ path: '../.env' });
const { sequelize } = require('./src/config/database');
const { User } = require('./src/models');
const bcrypt = require('bcrypt');

async function fixUserPasswordAgain() {
  try {
    await sequelize.authenticate();
    console.log('Database connected successfully');
    
    const user = await User.findOne({ where: { email: 'tshabalalasipho988@gmail.com' } });
    
    if (user) {
      console.log('User found:', user.email);
      console.log('Current hashed_password:', user.dataValues.hashed_password || 'null/empty');
      
      // Hash the password
      const hashedPassword = await bcrypt.hash('@Password2', 10);
      console.log('Generated password hash length:', hashedPassword.length);
      console.log('Generated password hash starts with:', hashedPassword.substring(0, 10));
      
      // Update the user using raw SQL to avoid model mapping issues
      await sequelize.query(`
        UPDATE users 
        SET password_hash = :passwordHash, 
            is_active = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE email = :email
      `, {
        replacements: {
          passwordHash: hashedPassword,
          email: 'tshabalalasipho988@gmail.com'
        },
        type: sequelize.QueryTypes.UPDATE
      });
      
      console.log('✅ Password updated successfully using raw SQL for:', user.email);
    } else {
      console.log('User NOT found in database');
    }
    
    await sequelize.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

fixUserPasswordAgain();
