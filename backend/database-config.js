// Database Configuration for Sharing
// Update these settings for your shared PostgreSQL database

const config = {
  // Your local PostgreSQL (for development)
  local: {
    user: 'postgres',
    host: 'localhost',
    database: 'flow_space',
    password: 'postgres',
    port: 5432,
  },
  
  // Shared PostgreSQL (for collaborators)
  shared: {
    user: 'flowspace_user',
    host: '172.19.48.1', // Your computer's IP address
    database: 'flow_space',
    password: 'FlowSpace2024!', // Shared password for collaborators
    port: 5432,
  },
  
  // Cloud PostgreSQL (if you move to cloud later)
  cloud: {
    user: 'postgres',
    host: 'your-cloud-host.com',
    database: 'flow_space',
    password: 'your-cloud-password',
    port: 5432,
  }
};

// Choose which database to use
// Set NODE_ENV=shared to use shared database
const ENVIRONMENT = process.env.NODE_ENV || 'local';
const selectedConfig = config[ENVIRONMENT] || config.local;

console.log(`🗄️ Using ${ENVIRONMENT} database configuration`);

module.exports = selectedConfig;
