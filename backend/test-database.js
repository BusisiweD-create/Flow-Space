const { Pool } = require('pg');
const dbConfig = require('./database-config');

async function testDatabase() {
  const pool = new Pool(dbConfig);
  let client;
  
  try {
    console.log('🧪 Testing database connection and data...\n');
    
    // Connect to database
    client = await pool.connect();
    console.log('✅ Connected to database successfully');
    
    // Test basic queries
    console.log('\n📊 Testing table queries...');
    
    // Check users table
    const usersResult = await client.query('SELECT COUNT(*) as count FROM users');
    console.log(`👥 Users: ${usersResult.rows[0].count}`);
    
    // Check user roles
    const rolesResult = await client.query('SELECT name, display_name FROM user_roles ORDER BY name');
    console.log('\n🔐 User roles:');
    rolesResult.rows.forEach(row => {
      console.log(`   - ${row.name}: ${row.display_name}`);
    });
    
    // Check permissions
    const permissionsResult = await client.query('SELECT name, description FROM permissions ORDER BY name');
    console.log('\n🔑 Permissions:');
    permissionsResult.rows.forEach(row => {
      console.log(`   - ${row.name}: ${row.description}`);
    });
    
    // Check role permissions
    const rolePermissionsResult = await client.query(`
      SELECT 
        ur.name as role_name,
        ur.display_name,
        COUNT(rp.permission_id) as permission_count
      FROM user_roles ur
      LEFT JOIN role_permissions rp ON ur.id = rp.role_id
      GROUP BY ur.id, ur.name, ur.display_name
      ORDER BY ur.name
    `);
    
    console.log('\n🔗 Role permissions:');
    rolePermissionsResult.rows.forEach(row => {
      console.log(`   - ${row.role_name} (${row.display_name}): ${row.permission_count} permissions`);
    });
    
    // Test user creation
    console.log('\n👤 Testing user creation...');
    const testEmail = 'test@example.com';
    const testPassword = 'hashed_password_here';
    const testName = 'Test User';
    const testRole = 'teamMember';
    
    // Check if user already exists
    const existingUser = await client.query('SELECT id FROM users WHERE email = $1', [testEmail]);
    
    if (existingUser.rows.length === 0) {
      const insertResult = await client.query(`
        INSERT INTO users (email, password_hash, name, role)
        VALUES ($1, $2, $3, $4)
        RETURNING id, email, name, role, created_at
      `, [testEmail, testPassword, testName, testRole]);
      
      console.log('✅ Test user created successfully');
      console.log(`   - ID: ${insertResult.rows[0].id}`);
      console.log(`   - Email: ${insertResult.rows[0].email}`);
      console.log(`   - Name: ${insertResult.rows[0].name}`);
      console.log(`   - Role: ${insertResult.rows[0].role}`);
    } else {
      console.log('ℹ️  Test user already exists');
    }
    
    // Test role-based permission checking
    console.log('\n🔍 Testing role-based permissions...');
    const permissionTest = await client.query(`
      SELECT 
        u.email,
        u.role,
        ur.display_name as role_display_name,
        p.name as permission_name,
        p.description as permission_description
      FROM users u
      JOIN user_roles ur ON u.role = ur.name
      JOIN role_permissions rp ON ur.id = rp.role_id
      JOIN permissions p ON rp.permission_id = p.id
      WHERE u.email = $1
      ORDER BY p.name
    `, [testEmail]);
    
    if (permissionTest.rows.length > 0) {
      console.log(`✅ User permissions for ${testEmail}:`);
      permissionTest.rows.forEach(row => {
        console.log(`   - ${row.permission_name}: ${row.permission_description}`);
      });
    } else {
      console.log('⚠️  No permissions found for test user');
    }
    
    // Test project and deliverable queries
    console.log('\n📋 Testing project data...');
    const projectsResult = await client.query('SELECT COUNT(*) as count FROM projects');
    console.log(`📁 Projects: ${projectsResult.rows[0].count}`);
    
    const deliverablesResult = await client.query('SELECT COUNT(*) as count FROM deliverables');
    console.log(`📦 Deliverables: ${deliverablesResult.rows[0].count}`);
    
    const sprintsResult = await client.query('SELECT COUNT(*) as count FROM sprints');
    console.log(`🏃 Sprints: ${sprintsResult.rows[0].count}`);
    
    // Test notifications
    const notificationsResult = await client.query('SELECT COUNT(*) as count FROM notifications');
    console.log(`🔔 Notifications: ${notificationsResult.rows[0].count}`);
    
    // Test audit logs
    const auditLogsResult = await client.query('SELECT COUNT(*) as count FROM audit_logs');
    console.log(`📝 Audit logs: ${auditLogsResult.rows[0].count}`);
    
    console.log('\n🎉 Database test completed successfully!');
    console.log('\n📝 Database is ready for the Flow-Space application');
    
  } catch (error) {
    console.error('❌ Database test failed:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Troubleshooting tips:');
      console.log('   - Make sure PostgreSQL is running');
      console.log('   - Check database connection settings');
      console.log('   - Run setup-database.js first to create the database');
    } else if (error.code === '42P01') {
      console.log('\n💡 Table does not exist - run setup-database.js first');
    }
    
    process.exit(1);
  } finally {
    if (client) {
      await client.release();
    }
    await pool.end();
  }
}

// Run test if this file is executed directly
if (require.main === module) {
  testDatabase();
}

module.exports = { testDatabase };
