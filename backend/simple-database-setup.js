const { Pool } = require('pg');
const dbConfig = require('./database-config');

async function setupSimpleDatabase() {
  let client;
  
  try {
    console.log('🚀 Setting up simple database for Flow-Space...\n');
    
    // Connect to flow_space database
    const flowSpaceConfig = {
      ...dbConfig,
      database: 'flow_space'
    };
    
    const pool = new Pool(flowSpaceConfig);
    client = await pool.connect();
    console.log('✅ Connected to flow_space database');
    
    // Create a simple users table if it doesn't exist
    console.log('📋 Creating users table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'teamMember',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login_at TIMESTAMP
      )
    `);
    console.log('✅ Users table created');
    
    // Create user roles table
    console.log('📋 Creating user_roles table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_roles (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL,
        display_name VARCHAR(100) NOT NULL,
        description TEXT,
        color VARCHAR(7),
        icon VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ User roles table created');
    
    // Create permissions table
    console.log('📋 Creating permissions table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS permissions (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) UNIQUE NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Permissions table created');
    
    // Create role_permissions table
    console.log('📋 Creating role_permissions table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS role_permissions (
        id SERIAL PRIMARY KEY,
        role_id INTEGER REFERENCES user_roles(id) ON DELETE CASCADE,
        permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(role_id, permission_id)
      )
    `);
    console.log('✅ Role permissions table created');
    
    // Insert user roles
    console.log('🌱 Inserting user roles...');
    await client.query(`
      INSERT INTO user_roles (name, display_name, description, color, icon) 
      VALUES 
        ('teamMember', 'Team Member', 'Can create deliverables and view own work', '#2196F3', 'person'),
        ('deliveryLead', 'Delivery Lead', 'Can manage team and submit for client review', '#FF9800', 'leaderboard'),
        ('clientReviewer', 'Client Reviewer', 'Can review and approve deliverables', '#4CAF50', 'verified_user'),
        ('systemAdmin', 'System Admin', 'Full system access and administration', '#9C27B0', 'admin_panel_settings')
      ON CONFLICT (name) DO NOTHING
    `);
    console.log('✅ User roles inserted');
    
    // Insert permissions
    console.log('🌱 Inserting permissions...');
    await client.query(`
      INSERT INTO permissions (name, description) 
      VALUES 
        ('create_deliverable', 'Create new deliverables'),
        ('edit_deliverable', 'Edit existing deliverables'),
        ('submit_for_review', 'Submit deliverables for client review'),
        ('approve_deliverable', 'Approve or reject deliverables'),
        ('view_team_dashboard', 'View team performance dashboard'),
        ('view_client_review', 'Access client review interface'),
        ('manage_users', 'Manage user accounts and roles'),
        ('view_audit_logs', 'View system audit logs'),
        ('view_all_deliverables', 'View all team deliverables')
      ON CONFLICT (name) DO NOTHING
    `);
    console.log('✅ Permissions inserted');
    
    // Insert role permissions
    console.log('🌱 Setting up role permissions...');
    
    // Team Member permissions
    await client.query(`
      INSERT INTO role_permissions (role_id, permission_id) 
      SELECT ur.id, p.id 
      FROM user_roles ur, permissions p 
      WHERE ur.name = 'teamMember' 
      AND p.name IN ('create_deliverable', 'edit_deliverable')
      ON CONFLICT (role_id, permission_id) DO NOTHING
    `);
    
    // Delivery Lead permissions
    await client.query(`
      INSERT INTO role_permissions (role_id, permission_id) 
      SELECT ur.id, p.id 
      FROM user_roles ur, permissions p 
      WHERE ur.name = 'deliveryLead' 
      AND p.name IN ('create_deliverable', 'edit_deliverable', 'submit_for_review', 'view_team_dashboard', 'view_all_deliverables')
      ON CONFLICT (role_id, permission_id) DO NOTHING
    `);
    
    // Client Reviewer permissions
    await client.query(`
      INSERT INTO role_permissions (role_id, permission_id) 
      SELECT ur.id, p.id 
      FROM user_roles ur, permissions p 
      WHERE ur.name = 'clientReviewer' 
      AND p.name IN ('approve_deliverable', 'view_client_review')
      ON CONFLICT (role_id, permission_id) DO NOTHING
    `);
    
    // System Admin permissions (all)
    await client.query(`
      INSERT INTO role_permissions (role_id, permission_id) 
      SELECT ur.id, p.id 
      FROM user_roles ur, permissions p 
      WHERE ur.name = 'systemAdmin'
      ON CONFLICT (role_id, permission_id) DO NOTHING
    `);
    
    console.log('✅ Role permissions configured');
    
    // Create a test admin user
    console.log('👤 Creating test admin user...');
    const testEmail = 'admin@flowspace.com';
    const testPassword = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'; // 'password'
    const testName = 'Admin User';
    const testRole = 'systemAdmin';
    
    await client.query(`
      INSERT INTO users (email, password_hash, name, role) 
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (email) DO UPDATE SET 
        password_hash = EXCLUDED.password_hash,
        name = EXCLUDED.name,
        role = EXCLUDED.role
    `, [testEmail, testPassword, testName, testRole]);
    
    console.log('✅ Test admin user created');
    console.log(`   - Email: ${testEmail}`);
    console.log(`   - Password: password`);
    console.log(`   - Role: ${testRole}`);
    
    // Verify setup
    console.log('\n🔍 Verifying setup...');
    
    const usersCount = await client.query('SELECT COUNT(*) as count FROM users');
    const rolesCount = await client.query('SELECT COUNT(*) as count FROM user_roles');
    const permissionsCount = await client.query('SELECT COUNT(*) as count FROM permissions');
    
    console.log(`📊 Users: ${usersCount.rows[0].count}`);
    console.log(`👥 Roles: ${rolesCount.rows[0].count}`);
    console.log(`🔐 Permissions: ${permissionsCount.rows[0].count}`);
    
    await client.release();
    await pool.end();
    
    console.log('\n🎉 Simple database setup completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('   1. Start the server: node server-updated.js');
    console.log('   2. Test the API endpoints');
    console.log('   3. Run the Flutter app');
    
  } catch (error) {
    console.error('❌ Database setup failed:', error.message);
    process.exit(1);
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  setupSimpleDatabase();
}

module.exports = { setupSimpleDatabase };
