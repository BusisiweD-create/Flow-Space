// Database pool configuration for ES Module compatibility
import pkg from 'pg';
const { Pool } = pkg;

// Environment-specific database configuration
function createPool() {
  const isProduction = process.env.NODE_ENV === 'production';
  const isRenderDeployed = process.env.RENDER === 'true' || process.env.RENDER_SERVICE_ID;
  
  console.log('🌍 Environment:', process.env.NODE_ENV || 'development');
  console.log('🚀 Render Deployed:', isRenderDeployed ? 'YES' : 'NO');
  
  if (isRenderDeployed || isProduction) {
    // Production/Render: Use DATABASE_URL (Render provides this automatically)
    console.log('🛜 Using DATABASE_URL for Production/Render');
    console.log('📊 Connection URL:', process.env.DATABASE_URL ? '***CONFIGURED***' : 'NOT SET');
    
    if (!process.env.DATABASE_URL) {
      console.error('❌ DATABASE_URL not set in production environment');
      throw new Error('DATABASE_URL is required in production');
    }

    return new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false,
      },
    });
  } else {
    // Local Development: Use individual settings or construct DATABASE_URL
    console.log('🏠 Using Local Development Database');
    
    const dbHost = process.env.DB_HOST || '127.0.0.1';
    const dbPort = parseInt(process.env.DB_PORT || '5432', 10);
    const dbName = process.env.DB_NAME || 'flow_space';
    const dbUser = process.env.DB_USER || 'postgres';
    const dbPassword = process.env.DB_PASSWORD || 'postgres';
    const dbSSL = process.env.DB_SSL === 'true';
    
    console.log(`📊 Local DB: ${dbUser}@${dbHost}:${dbPort}/${dbName}`);
    
    return new Pool({
      host: dbHost,
      port: dbPort,
      database: dbName,
      user: dbUser,
      password: dbPassword,
      ssl: dbSSL ? {
        rejectUnauthorized: false,
      } : false,
    });
  }
}

const pool = createPool();

// Test database connection
pool.on('connect', () => {
  const env = process.env.NODE_ENV || 'development';
  console.log(`✅ Connected to PostgreSQL database (${env})`);
});

pool.on('error', (err) => {
  console.error('❌ Database pool error:', err);
});

export default pool;
