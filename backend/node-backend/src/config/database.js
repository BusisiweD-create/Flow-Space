const { Sequelize } = require('sequelize');
const path = require('path');
require('dotenv').config();

// Determine database type from DATABASE_URL or default to SQLite for development
const databaseUrl = process.env.DATABASE_URL || '';
let sequelize;

if (databaseUrl.includes('postgresql://')) {
  // PostgreSQL configuration
  sequelize = new Sequelize(databaseUrl, {
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
} else {
  // SQLite configuration (default for development)
  const sqlitePath = process.env.SQLITE_PATH || path.join(__dirname, '..', '..', '..', 'backend', 'hackathon-backend', 'hackathon.db');
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: sqlitePath,
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
  console.log(`Using SQLite database at: ${sqlitePath}`);
}

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