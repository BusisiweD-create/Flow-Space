// Migrate real Gmail user from profiles to users table
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function migrateGmailUser() {
  try {
    console.log('🔄 Migrating your real Gmail account to users table...\n');
    
    // Get the Gmail user from profiles table
    const profileResult = await pool.query(`
      SELECT id, email, password_hash, first_name, last_name, role, created_at, updated_at
      FROM profiles 
      WHERE email = 'busisiwe.test@gmail.com'
    `);
    
    if (profileResult.rows.length === 0) {
      console.log('❌ Gmail user not found in profiles table');
      return;
    }
    
    const profile = profileResult.rows[0];
    console.log(`👤 Found your Gmail account: ${profile.first_name} ${profile.last_name} (${profile.email})`);
    console.log(`   📅 Created: ${new Date(profile.created_at).toLocaleString()}`);
    
    // Check if user already exists in users table
    const existingUser = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [profile.email]);
    
    if (existingUser.rows.length > 0) {
      console.log('⚠️  Gmail user already exists in users table');
      console.log('💡 You can login with:');
      console.log(`   Email: ${profile.email}`);
      console.log(`   Password: [your original password]`);
      return;
    }
    
    // Migrate the user to users table
    const fullName = `${profile.first_name} ${profile.last_name}`;
    const result = await pool.query(`
      INSERT INTO users (id, email, password_hash, name, role, is_active, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `, [
      profile.id, // Keep original ID
      profile.email,
      profile.password_hash, // Keep original password hash
      fullName,
      profile.role || 'user', // Use profile role or default to user
      true, // Set as active
      profile.created_at,
      profile.updated_at
    ]);
    
    console.log('✅ Gmail user migrated successfully!');
    console.log(`   👤 Name: ${result.rows[0].name}`);
    console.log(`   📧 Email: ${result.rows[0].email}`);
    console.log(`   🎭 Role: ${result.rows[0].role}`);
    console.log(`   📅 Created: ${new Date(result.rows[0].created_at).toLocaleString()}`);
    
    console.log('\n🎉 Migration completed!');
    console.log('💡 You can now login with your Gmail account:');
    console.log(`   Email: ${profile.email}`);
    console.log(`   Password: [your original password]`);
    
  } catch (error) {
    console.error('❌ Error migrating Gmail user:', error.message);
  } finally {
    await pool.end();
  }
}

migrateGmailUser();
