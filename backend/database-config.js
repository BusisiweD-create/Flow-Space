// Database Configuration for Sharing
// Update these settings for your shared PostgreSQL database

const config = {
  // Your local PostgreSQL (for development/owner)
  local: {
    user: 'postgres',
    host: 'localhost',           // Use localhost when running on same machine
    database: 'flow_space',      // Your actual shared database
    password: 'postgres',        // Your postgres password
    port: 5432,
  },
  
  // Shared PostgreSQL (for collaborators on same network)
  shared: {
    user: 'flowspace_user',
    host: '172.19.48.1',
    database: 'flow_space',
    password: 'FlowSpace2024!',
    port: 5432
  },
  
  // Cloud PostgreSQL (if you move to cloud later)
  cloud: {
    user: 'flow_space_db_user',
    host: 'dpg-d4qrsbs9c44c73bisgbg-a',
    database: 'flow_space_db',
    password: 'QGKheJOkRQ0jj9La1FYN0jONXUqRNfW5',
    port: 5432,
    ssl: { rejectUnauthorized: false }
  }
};

// Choose which database to use
// Set NODE_ENV=shared to use shared database
const ENVIRONMENT = process.env.NODE_ENV || 'cloud';

const envBasedConfig = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } }
  : (process.env.DB_HOST || process.env.DB_USER || process.env.DB_PASSWORD || process.env.DB_NAME || process.env.DB_PORT)
    ? {
        user: process.env.DB_USER || 'postgres',
        host: process.env.DB_HOST || 'localhost',
        database: process.env.DB_NAME || 'flow_space',
        password: process.env.DB_PASSWORD || 'postgres',
        port: parseInt(process.env.DB_PORT, 10) || 5432,
        ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
      }
    : null;

const selectedConfig = envBasedConfig || config[ENVIRONMENT] || config.local;

console.log(`🗄️ Using ${envBasedConfig ? 'env' : ENVIRONMENT} database configuration`);

module.exports = selectedConfig;
