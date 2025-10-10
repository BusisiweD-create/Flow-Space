const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Database configuration options
const dbOptions = {
  // Option 1: Local PostgreSQL (if installed)
  local: {
    user: 'postgres',
    host: 'localhost',
    database: 'postgres',
    password: 'postgres',
    port: 5432,
  },
  
  // Option 2: Cloud database (Neon, Supabase, etc.)
  cloud: {
    user: process.env.DB_USER || 'your_username',
    host: process.env.DB_HOST || 'your_host',
    database: process.env.DB_NAME || 'your_database',
    password: process.env.DB_PASSWORD || 'your_password',
    port: process.env.DB_PORT || 5432,
    ssl: { rejectUnauthorized: false }
  },
  
  // Option 3: Docker PostgreSQL
  docker: {
    user: 'postgres',
    host: 'localhost',
    database: 'postgres',
    password: 'postgres',
    port: 5432,
  }
};

async function testDatabaseConnection(config, name) {
  console.log(`\n🧪 Testing ${name} database connection...`);
  
  try {
    const pool = new Pool(config);
    const client = await pool.connect();
    console.log(`✅ ${name} database connected successfully`);
    
    // Test basic query
    const result = await client.query('SELECT version()');
    console.log(`📊 PostgreSQL version: ${result.rows[0].version.split(' ')[0]}`);
    
    await client.release();
    await pool.end();
    return true;
  } catch (error) {
    console.log(`❌ ${name} database connection failed: ${error.message}`);
    return false;
  }
}

async function setupDatabaseWithConfig(config, name) {
  console.log(`\n🗄️ Setting up database with ${name} configuration...`);
  
  try {
    const pool = new Pool(config);
    const client = await pool.connect();
    console.log(`✅ Connected to ${name} database`);
    
    // Create database if it doesn't exist
    try {
      await client.query('CREATE DATABASE flow_space');
      console.log('✅ Database "flow_space" created');
    } catch (error) {
      if (error.code === '42P04') {
        console.log('ℹ️  Database "flow_space" already exists');
      } else {
        throw error;
      }
    }
    
    await client.release();
    await pool.end();
    
    // Connect to the new database
    const flowSpaceConfig = {
      ...config,
      database: 'flow_space'
    };
    
    const flowSpacePool = new Pool(flowSpaceConfig);
    const flowSpaceClient = await flowSpacePool.connect();
    console.log('✅ Connected to flow_space database');
    
    // Read and execute schema
    console.log('📋 Creating tables...');
    const schemaPath = path.join(__dirname, 'database', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Split schema into individual statements and execute
    const statements = schema
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    for (const statement of statements) {
      if (statement.trim()) {
        try {
          await flowSpaceClient.query(statement);
        } catch (error) {
          if (!error.message.includes('already exists') && 
              !error.message.includes('does not exist')) {
            console.warn(`⚠️  Warning executing statement: ${error.message}`);
          }
        }
      }
    }
    console.log('✅ Tables created successfully');
    
    // Read and execute seed data
    console.log('🌱 Inserting seed data...');
    const seedPath = path.join(__dirname, 'database', 'seed_data.sql');
    const seedData = fs.readFileSync(seedPath, 'utf8');
    
    const seedStatements = seedData
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    for (const statement of seedStatements) {
      if (statement.trim()) {
        try {
          await flowSpaceClient.query(statement);
        } catch (error) {
          console.warn(`⚠️  Warning executing seed statement: ${error.message}`);
        }
      }
    }
    console.log('✅ Seed data inserted successfully');
    
    await flowSpaceClient.release();
    await flowSpacePool.end();
    
    return flowSpaceConfig;
    
  } catch (error) {
    console.error(`❌ Database setup failed with ${name}:`, error.message);
    return null;
  }
}

async function main() {
  console.log('🚀 Flow-Space Database Setup Options\n');
  
  console.log('📋 Available database options:');
  console.log('1. Local PostgreSQL (if installed)');
  console.log('2. Cloud database (Neon, Supabase, etc.)');
  console.log('3. Docker PostgreSQL');
  console.log('4. Manual setup instructions\n');
  
  // Test all connection options
  const localConnected = await testDatabaseConnection(dbOptions.local, 'Local PostgreSQL');
  const cloudConnected = await testDatabaseConnection(dbOptions.cloud, 'Cloud Database');
  const dockerConnected = await testDatabaseConnection(dbOptions.docker, 'Docker PostgreSQL');
  
  let selectedConfig = null;
  
  if (localConnected) {
    console.log('\n🎯 Using Local PostgreSQL...');
    selectedConfig = await setupDatabaseWithConfig(dbOptions.local, 'Local PostgreSQL');
  } else if (cloudConnected) {
    console.log('\n🎯 Using Cloud Database...');
    selectedConfig = await setupDatabaseWithConfig(dbOptions.cloud, 'Cloud Database');
  } else if (dockerConnected) {
    console.log('\n🎯 Using Docker PostgreSQL...');
    selectedConfig = await setupDatabaseWithConfig(dbOptions.docker, 'Docker PostgreSQL');
  } else {
    console.log('\n❌ No database connections available');
    console.log('\n💡 Manual setup options:');
    console.log('1. Install PostgreSQL manually:');
    console.log('   - Download from: https://www.postgresql.org/download/windows/');
    console.log('   - Install with default settings');
    console.log('   - Add PostgreSQL to your PATH');
    console.log('   - Run this script again');
    console.log('\n2. Use a cloud database:');
    console.log('   - Sign up for Neon (https://neon.tech)');
    console.log('   - Or Supabase (https://supabase.com)');
    console.log('   - Get connection details');
    console.log('   - Set environment variables:');
    console.log('     DB_HOST=your_host');
    console.log('     DB_USER=your_username');
    console.log('     DB_PASSWORD=your_password');
    console.log('     DB_NAME=your_database');
    console.log('   - Run this script again');
    console.log('\n3. Use Docker:');
    console.log('   - Install Docker Desktop');
    console.log('   - Run: docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres');
    console.log('   - Run this script again');
    return;
  }
  
  if (selectedConfig) {
    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('1. Update your backend server configuration');
    console.log('2. Test the API endpoints');
    console.log('3. Run the Flutter app');
    
    // Update database config file
    const configContent = `// Database Configuration for Flow-Space
// This file was auto-generated by setup-database-options.js

const config = {
  // Active configuration
  active: ${JSON.stringify(selectedConfig, null, 2)},
  
  // All available configurations
  local: ${JSON.stringify(dbOptions.local, null, 2)},
  cloud: ${JSON.stringify(dbOptions.cloud, null, 2)},
  docker: ${JSON.stringify(dbOptions.docker, null, 2)}
};

// Use the active configuration
module.exports = config.active;
`;
    
    fs.writeFileSync('database-config-updated.js', configContent);
    console.log('\n✅ Database configuration saved to database-config-updated.js');
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { main, testDatabaseConnection, setupDatabaseWithConfig };
