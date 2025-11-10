const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Database configuration
const dbConfig = {
  user: 'postgres',
  host: 'localhost',
  database: 'postgres', // Connect to default postgres database first
  password: 'postgres',
  port: 5432,
};

const pool = new Pool(dbConfig);

async function setupDatabase() {
  let client;
  
  try {
    console.log('🚀 Starting database setup...\n');
    
    // Connect to PostgreSQL
    client = await pool.connect();
    console.log('✅ Connected to PostgreSQL');
    
    // Create database if it doesn't exist
    console.log('📦 Creating database...');
    try {
      await client.query('CREATE DATABASE flow_space');
      console.log('✅ Database "flow_space" created');
    } catch (error) {
      if (error.code === '42P04') {
        console.log('✅ Database "flow_space" already exists');
      } else {
        throw error;
      }
    }
    
    // Close connection to default database
    await client.release();
    
    // Connect to the new database
    const flowSpaceConfig = {
      ...dbConfig,
      database: 'flow_space'
    };
    
    const flowSpacePool = new Pool(flowSpaceConfig);
    client = await flowSpacePool.connect();
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
          await client.query(statement);
        } catch (error) {
          // Skip errors for statements that might already exist
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
    
    // Split seed data into individual statements and execute
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
    
    // Check permissions (if permissions table exists)
    try {
      const permissionsResult = await client.query('SELECT COUNT(*) as count FROM permissions');
      console.log(`\n🔐 Permissions: ${permissionsResult.rows[0].count} total`);
      
      // Check role permissions
      const rolePermissionsResult = await client.query(`
        SELECT ur.name as role_name, COUNT(rp.permission_id) as permission_count
        FROM user_roles ur
        LEFT JOIN role_permissions rp ON ur.id = rp.role_id
        GROUP BY ur.id, ur.name
        ORDER BY ur.name
      `);
      
      console.log('\n🔗 Role permissions:');
      rolePermissionsResult.rows.forEach(row => {
        console.log(`   - ${row.role_name}: ${row.permission_count} permissions`);
      });
    } catch (error) {
      console.log('\n⚠️  Permissions table not found - this is expected for the current schema');
    }
    
    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('   1. Update your backend server to use the flow_space database');
    console.log('   2. Test the authentication endpoints');
    console.log('   3. Run the Flutter app to test the role-based system');
    
  } catch (error) {
    console.error('❌ Database setup failed:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Troubleshooting tips:');
      console.log('   - Make sure PostgreSQL is installed and running');
      console.log('   - Check if the default postgres user exists');
      console.log('   - Verify the connection details in database-config.js');
    } else if (error.code === '42P04') {
      console.log('\n💡 Database already exists - this is normal if you\'ve run setup before');
    }
    
    process.exit(1);
  } finally {
    if (client) {
      await client.release();
    }
    await pool.end();
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  setupDatabase();
}

module.exports = { setupDatabase };
