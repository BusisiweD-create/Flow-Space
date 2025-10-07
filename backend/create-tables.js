const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const dbConfig = require('./database-config');

async function createTables() {
  let client;
  
  try {
    console.log('🗄️ Creating tables in existing database...\n');
    
    // Connect to flow_space database
    const flowSpaceConfig = {
      ...dbConfig,
      database: 'flow_space'
    };
    
    const pool = new Pool(flowSpaceConfig);
    client = await pool.connect();
    console.log('✅ Connected to flow_space database');
    
    // Check if tables already exist
    const tablesCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'users'
    `);
    
    if (tablesCheck.rows.length > 0) {
      console.log('ℹ️  Tables already exist. Dropping and recreating...');
      
      // Drop all tables in reverse order
      const dropStatements = [
        'DROP TABLE IF EXISTS audit_logs CASCADE',
        'DROP TABLE IF EXISTS notifications CASCADE',
        'DROP TABLE IF EXISTS client_reviews CASCADE',
        'DROP TABLE IF EXISTS sign_off_reports CASCADE',
        'DROP TABLE IF EXISTS sprint_deliverables CASCADE',
        'DROP TABLE IF EXISTS sprints CASCADE',
        'DROP TABLE IF EXISTS deliverables CASCADE',
        'DROP TABLE IF EXISTS project_members CASCADE',
        'DROP TABLE IF EXISTS projects CASCADE',
        'DROP TABLE IF EXISTS role_permissions CASCADE',
        'DROP TABLE IF EXISTS permissions CASCADE',
        'DROP TABLE IF EXISTS user_roles CASCADE',
        'DROP TABLE IF EXISTS users CASCADE',
        'DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE'
      ];
      
      for (const statement of dropStatements) {
        try {
          await client.query(statement);
        } catch (error) {
          // Ignore errors for non-existent objects
        }
      }
      console.log('✅ Existing tables dropped');
    }
    
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
          await client.query(statement);
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
          await client.query(statement);
        } catch (error) {
          console.warn(`⚠️  Warning executing seed statement: ${error.message}`);
        }
      }
    }
    console.log('✅ Seed data inserted successfully');
    
    // Verify setup
    console.log('\n🔍 Verifying database setup...');
    
    // Check tables
    const tablesResult = await client.query(`
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
    const rolesResult = await client.query('SELECT name, display_name FROM user_roles ORDER BY name');
    console.log('\n👥 User roles:');
    rolesResult.rows.forEach(row => {
      console.log(`   - ${row.name}: ${row.display_name}`);
    });
    
    // Check permissions
    const permissionsResult = await client.query('SELECT COUNT(*) as count FROM permissions');
    console.log(`\n🔐 Permissions: ${permissionsResult.rows[0].count} total`);
    
    // Test user creation
    console.log('\n👤 Testing user creation...');
    const testEmail = 'admin@flowspace.com';
    const testPassword = 'hashed_password_here';
    const testName = 'Admin User';
    const testRole = 'systemAdmin';
    
    // Check if user already exists
    const existingUser = await client.query('SELECT id FROM users WHERE email = $1', [testEmail]);
    
    if (existingUser.rows.length === 0) {
      const insertResult = await client.query(`
        INSERT INTO users (id, email, password_hash, name, role)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id, email, name, role, created_at
      `, [require('uuid').v4(), testEmail, testPassword, testName, testRole]);
      
      console.log('✅ Test user created successfully');
      console.log(`   - ID: ${insertResult.rows[0].id}`);
      console.log(`   - Email: ${insertResult.rows[0].email}`);
      console.log(`   - Name: ${insertResult.rows[0].name}`);
      console.log(`   - Role: ${insertResult.rows[0].role}`);
    } else {
      console.log('ℹ️  Test user already exists');
    }
    
    await client.release();
    await pool.end();
    
    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('   1. Test the database: node test-database.js');
    console.log('   2. Start the server: node server-updated.js');
    console.log('   3. Test the API endpoints');
    
  } catch (error) {
    console.error('❌ Database setup failed:', error.message);
    process.exit(1);
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  createTables();
}

module.exports = { createTables };
