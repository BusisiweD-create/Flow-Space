const { Sequelize } = require('sequelize');
require('dotenv').config();

const DB_HOST = process.env.DB_HOST;
const DB_PORT = process.env.DB_PORT || '5432';
const DB_NAME = process.env.DB_NAME;
const DB_USER = process.env.DB_USER;
const DB_PASSWORD = process.env.DB_PASSWORD;
const DATABASE_URL = process.env.DATABASE_URL;
const NODE_ENV = process.env.NODE_ENV || 'development';

let sequelize;

// Use SQLite for development, PostgreSQL for production
const hasPostgresEnv = !!(DB_HOST && DB_NAME && DB_USER && DB_PASSWORD);
const hasDatabaseUrl = typeof DATABASE_URL === 'string' && DATABASE_URL.trim().length > 0;
const useSqlite = (NODE_ENV !== 'production') && (!hasPostgresEnv && !hasDatabaseUrl || DB_USER === 'sqlite');

if (useSqlite) {
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: DB_NAME || './database.sqlite',
    logging: console.log,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
} else {
  if (!hasPostgresEnv && !hasDatabaseUrl) {
    throw new Error('Missing PostgreSQL env vars: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD');
  }

  const dialectOptions = NODE_ENV === 'production' ? {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  } : {};

  sequelize = hasDatabaseUrl
    ? new Sequelize(DATABASE_URL, {
        dialect: 'postgres',
        logging: NODE_ENV === 'development' ? console.log : false,
        pool: {
          max: 10,
          min: 0,
          acquire: 30000,
          idle: 10000
        },
        dialectOptions
      })
    : new Sequelize(DB_NAME, DB_USER, DB_PASSWORD, {
        host: DB_HOST,
        port: parseInt(DB_PORT, 10),
        dialect: 'postgres',
        logging: NODE_ENV === 'development' ? console.log : false,
        pool: {
          max: 10,
          min: 0,
          acquire: 30000,
          idle: 10000
        },
        dialectOptions
      });
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
async function syncDatabase({ force = false, alter = true } = {}) {
  try {
    await sequelize.sync({ force, alter });
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