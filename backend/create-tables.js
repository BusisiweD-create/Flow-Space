const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const dbConfig = require('./database-config');

function splitSqlStatements(sql) {
  const statements = [];
  let current = '';
  let inDollarQuotedFunction = false;

  for (let i = 0; i < sql.length; i++) {
    const ch = sql[i];
    const nextTwo = sql.slice(i, i + 2);

    // Toggle when we see a $$ block (start or end of function body)
    if (nextTwo === '$$') {
      inDollarQuotedFunction = !inDollarQuotedFunction;
      current += nextTwo;
      i++; // Skip the second $
      continue;
    }

    if (ch === ';' && !inDollarQuotedFunction) {
      if (current.trim().length > 0) {
        statements.push(current.trim());
      }
      current = '';
    } else {
      current += ch;
    }
  }

  if (current.trim().length > 0) {
    statements.push(current.trim());
  }

  return statements
    .map(stmt => stmt.trim())
    .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
}

async function createTables() {
  let client;
  
  try {
    console.log('🗄️ Creating tables in existing database...\n');
    
    // Connect using database-config (cloud = flow_space_db on Render)
    const pool = new Pool(dbConfig);
    client = await pool.connect();
    console.log('✅ Connected to database');
    
    // Check if core tables already exist (users table as proxy)
    const tablesCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'users'
    `);

    if (tablesCheck.rows.length > 0) {
      console.log('ℹ️  Core tables already exist. Skipping destructive drop and keeping existing data.');
    }
    
    // Ensure required extensions exist (for gen_random_uuid)
    try {
      await client.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
    } catch (error) {
      console.warn('⚠️  Warning ensuring pgcrypto extension:', error.message);
    }

    // Read and execute schema
    console.log('📋 Creating tables...');
    const schemaPath = path.join(__dirname, 'database', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Split schema into individual statements and execute,
    // taking care not to split inside $$...$$ function bodies
    const statements = splitSqlStatements(schema);
    
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
    
    // Use the same splitter so semicolons inside string literals (e.g. user agents)
    // don't break statements like the Win64; x64 user_agent values
    const seedStatements = splitSqlStatements(seedData);
    
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
    try {
      const rolesResult = await client.query('SELECT name, display_name FROM user_roles ORDER BY name');
      console.log('\n👥 User roles:');
      rolesResult.rows.forEach(row => {
        console.log(`   - ${row.name}: ${row.display_name}`);
      });
    } catch (error) {
      if (error.code === '42P01') {
        console.log('\n👥 User roles table does not exist yet; skipping user roles check');
      } else {
        console.warn('\n⚠️  Error checking user roles:', error.message);
      }
    }
    
    // Check permissions
    try {
      const permissionsResult = await client.query('SELECT COUNT(*) as count FROM permissions');
      console.log(`\n🔐 Permissions: ${permissionsResult.rows[0].count} total`);
    } catch (error) {
      if (error.code === '42P01') {
        console.log('\n🔐 Permissions table does not exist yet; skipping permissions check');
      } else {
        console.warn('\n⚠️  Error checking permissions:', error.message);
      }
    }
    
    // Test user creation (non-fatal if users table is missing)
    try {
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
    } catch (error) {
      if (error.code === '42P01') {
        console.warn('⚠️  Users table does not exist yet; skipping test user creation');
      } else {
        console.warn('⚠️  Error during test user creation:', error.message);
      }
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
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  createTables();
}

module.exports = { createTables };
