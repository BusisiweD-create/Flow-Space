const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const dbConfig = require('./database-config');

async function resetDatabase() {
  let client;
  
  try {
    console.log('🔄 Resetting Flow-Space database...\n');
    
    // Connect to PostgreSQL
    const pool = new Pool(dbConfig);
    client = await pool.connect();
    console.log('✅ Connected to PostgreSQL');
    
    // Drop database if it exists
    console.log('🗑️  Dropping existing database...');
    try {
      await client.query('DROP DATABASE IF EXISTS flow_space');
      console.log('✅ Database dropped successfully');
    } catch (error) {
      console.log('ℹ️  Database may not exist or is in use');
    }
    
    // Create database
    console.log('📦 Creating fresh database...');
    await client.query('CREATE DATABASE flow_space');
    console.log('✅ Database "flow_space" created');
    
    await client.release();
    await pool.end();
    
    // Connect to the new database
    const flowSpaceConfig = {
      ...dbConfig,
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
          console.warn(`⚠️  Warning executing statement: ${error.message}`);
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
    
    // Verify setup
    console.log('\n🔍 Verifying database setup...');
    
    // Check tables
    const tablesResult = await flowSpaceClient.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    
    console.log('📊 Created tables:');
    tablesResult.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });
    
    // Check user roles
    const rolesResult = await flowSpaceClient.query('SELECT name, display_name FROM user_roles ORDER BY name');
    console.log('\n👥 User roles:');
    rolesResult.rows.forEach(row => {
      console.log(`   - ${row.name}: ${row.display_name}`);
    });
    
    // Check permissions
    const permissionsResult = await flowSpaceClient.query('SELECT COUNT(*) as count FROM permissions');
    console.log(`\n🔐 Permissions: ${permissionsResult.rows[0].count} total`);
    
    await flowSpaceClient.release();
    await flowSpacePool.end();
    
    console.log('\n🎉 Database reset completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('   1. Test the database: node test-database.js');
    console.log('   2. Start the server: node server-updated.js');
    console.log('   3. Test the API endpoints');
    
  } catch (error) {
    console.error('❌ Database reset failed:', error.message);
    process.exit(1);
  }
}

// Run reset if this file is executed directly
if (require.main === module) {
  resetDatabase();
}

module.exports = { resetDatabase };
