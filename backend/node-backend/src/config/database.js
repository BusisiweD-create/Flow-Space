const { Sequelize } = require('sequelize');
require('dotenv').config();

// PostgreSQL configuration - only real database, no fallback
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl || !databaseUrl.includes('postgresql://')) {
  throw new Error('DATABASE_URL environment variable is required and must be a PostgreSQL connection string');
}

const sequelize = new Sequelize(databaseUrl, {
  dialect: 'postgres',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000
  },
  dialectOptions: process.env.NODE_ENV === 'production' ? {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  } : {}
});

// Test database connection
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully');
    return true;
  } catch (error) {
    console.error('❌ Unable to connect to the database:', error);
    return false;
  }
}

// Sync database tables
async function syncDatabase(force = false) {
  try {
    await sequelize.sync({ force });
    console.log('Database synchronized successfully.');
    return true;
  } catch (error) {
    console.error('Error synchronizing database:', error);
    return false;
  }
}

module.exports = {
  sequelize,
  testConnection,
  syncDatabase
};