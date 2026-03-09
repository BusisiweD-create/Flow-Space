require('dotenv').config({path: '../.env'});
const { sequelize } = require('./src/models');

async function checkDatabaseSchema() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');
    
    // Get table schema
    const [results] = await sequelize.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Users table schema:');
    results.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await sequelize.close();
  }
}

checkDatabaseSchema();
