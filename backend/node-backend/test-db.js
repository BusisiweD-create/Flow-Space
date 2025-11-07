const { testConnection } = require('./src/config/database');

async function testDB() {
  console.log('Testing database connection...');
  const connected = await testConnection();
  if (connected) {
    console.log('✅ Database connection successful!');
  } else {
    console.log('❌ Database connection failed');
  }
}

testDB().catch(console.error);