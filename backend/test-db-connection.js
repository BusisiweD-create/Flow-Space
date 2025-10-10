const { Pool } = require('pg');
const dbConfig = require('./database-config');

console.log('🧪 Testing database connection...');
console.log('Config:', dbConfig);

const pool = new Pool(dbConfig);

async function testConnection() {
  try {
    console.log('🔌 Attempting to connect to database...');
    const client = await pool.connect();
    console.log('✅ Database connection successful!');
    
    // Test a simple query
    const result = await client.query('SELECT NOW() as current_time');
    console.log('📅 Current time from database:', result.rows[0].current_time);
    
    // Test if profiles table exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles'
      );
    `);
    console.log('📊 Profiles table exists:', tableCheck.rows[0].exists);
    
    client.release();
    console.log('✅ Database test completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Database connection failed:');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

testConnection();
