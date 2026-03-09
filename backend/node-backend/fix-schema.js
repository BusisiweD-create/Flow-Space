require('dotenv').config({path: '../.env'});
const { sequelize } = require('./src/models');

async function addPasswordColumn() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');
    
    // Add password_hash column if it doesn't exist
    await sequelize.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NOT NULL DEFAULT ''
    `);
    
    console.log('✅ Added password_hash column');
    
    // Add email_verified column if it doesn't exist
    await sequelize.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false
    `);
    
    console.log('✅ Added email_verified column');
    
    // Add verification_code column if it doesn't exist
    await sequelize.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS verification_code VARCHAR(255)
    `);
    
    console.log('✅ Added verification_code column');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await sequelize.close();
  }
}

addPasswordColumn();
