// Database Configuration for Sharing
// Update these settings for your shared PostgreSQL database

const config = {
  // Your local PostgreSQL (for development/owner)
  local: {
    user: 'postgres',
    host: 'localhost',           // ✅ Use localhost when running on same machine
    database: 'flow_space',      // ✅ Your actual shared database
    password: 'postgres',        // ✅ Your postgres password
    port: 5432,
  },
  
  // Shared PostgreSQL (for collaborators on same network)
  shared: {
    user: 'flowspace_user',      // ✅ Collaborator user
    host: '172.19.48.1',         // ✅ Your IP address for network sharing
    database: 'flow_space',      // ✅ Shared database name
    password: 'FlowSpace2024!',  // ✅ Collaborator password
    port: 5432,
  },
  
  // Cloud PostgreSQL (if you move to cloud later)
  cloud: {
    user: 'postgres',
    host: 'your-cloud-host.com',
    database: 'flow_space',
    password: 'your-cloud-password',
    port: 5432,
    ssl: { rejectUnauthorized: false }
  }
};

// Choose which database to use
// Set NODE_ENV=shared to use shared database
const ENVIRONMENT = process.env.NODE_ENV || 'local';
const selectedConfig = config[ENVIRONMENT] || config.local;

console.log(`🗄️ Using ${ENVIRONMENT} database configuration`);

module.exports = selectedConfig;
