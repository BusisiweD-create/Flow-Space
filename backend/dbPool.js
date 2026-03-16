// Database pool configuration for ES Module compatibility
import pkg from 'pg';
const { Pool } = pkg;

// Safest approach: Use ONLY DATABASE_URL to avoid credential mismatches
function createPool() {
  console.log('🛜 Using DATABASE_URL (safest approach)');
  console.log('📊 Connection URL:', process.env.DATABASE_URL ? '***CONFIGURED***' : 'NOT SET');
  
  if (!process.env.DATABASE_URL) {
    return new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      ssl: false,
    });
  }

  // SAFE SSL CONFIGURATION - Respect DB_SSL setting
  const sslEnabled = process.env.DB_SSL === 'true';
  console.log('🔒 SSL Enabled:', sslEnabled);
  
  if (!process.env.DATABASE_URL) {
    return new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      ssl: sslEnabled,
    });
  }

  return new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: sslEnabled ? {
      rejectUnauthorized: false,
    } : false,
  });
}

const pool = createPool();

// Test database connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database via DATABASE_URL');
});

export default pool;
