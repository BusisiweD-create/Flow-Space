const { Pool } = require('pg');
const dbConfig = require('./database-config');

async function createEssentialTables() {
  const pool = new Pool(dbConfig);
  const client = await pool.connect();
  
  try {
    console.log('🚀 Creating essential tables for role management...');
    
    // Create users table
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
    
    // Create user_roles table
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_roles (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL,
        display_name VARCHAR(100) NOT NULL,
        color VARCHAR(7),
        icon VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ User roles table created');
    
    // Insert default roles
    await client.query(`
      INSERT INTO user_roles (name, display_name, color, icon) VALUES
      ('teamMember', 'Team Member', '#3B82F6', 'person'),
      ('deliveryLead', 'Delivery Lead', '#10B981', 'leaderboard'),
      ('clientReviewer', 'Client Reviewer', '#8B5CF6', 'visibility'),
      ('systemAdmin', 'System Admin', '#EF4444', 'admin_panel_settings')
      ON CONFLICT (name) DO NOTHING
    `);
    console.log('✅ Default roles inserted');
    
    // Create audit_logs table
    await client.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID,
        action VARCHAR(100) NOT NULL,
        resource_type VARCHAR(50),
        resource_id UUID,
        details JSONB DEFAULT '{}',
        ip_address INET,
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Audit logs table created');
    
    // Create updated_at trigger function
    await client.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);
    
    // Apply updated_at trigger to users table
    await client.query(`
      CREATE OR REPLACE TRIGGER update_users_updated_at 
      BEFORE UPDATE ON users
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
    `);
    
    console.log('🎉 Essential tables created successfully!');
    
    // Verify the setup
    const tables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('users', 'user_roles', 'audit_logs')
    `);
    
    console.log('📊 Created tables:');
    tables.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });
    
    const roles = await client.query('SELECT name, display_name FROM user_roles ORDER BY name');
    console.log('👥 Available roles:');
    roles.rows.forEach(row => {
      console.log(`   - ${row.name}: ${row.display_name}`);
    });
    
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  createEssentialTables()
    .then(() => {
      console.log('✅ Essential database setup completed');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Setup failed:', error.message);
      process.exit(1);
    });
}

module.exports = { createEssentialTables };