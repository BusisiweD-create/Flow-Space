// Check existing users in database - simplified version
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function checkUsers() {
  try {
    console.log('🔍 Checking existing users in your database...\n');
    
    // First, check the table structure
    const structureResult = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND table_schema = 'public'
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Users table structure:');
    structureResult.rows.forEach(col => {
      console.log(`   - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? '(required)' : '(optional)'}`);
    });
    console.log('');
    
    // Get all users with basic info
    const result = await pool.query(`
      SELECT *
      FROM users 
      ORDER BY created_at DESC
    `);
    
    console.log(`📊 Found ${result.rows.length} users in the database:\n`);
    
    if (result.rows.length === 0) {
      console.log('⚠️  No users found in the database');
      console.log('💡 You may need to register new users or restore from backup');
    } else {
      result.rows.forEach((user, index) => {
        console.log(`${index + 1}. 👤 User ID: ${user.id}`);
        console.log(`   📧 Email: ${user.email || 'Not set'}`);
        console.log(`   👤 Name: ${user.name || 'Not set'}`);
        console.log(`   🎭 Role: ${user.role || 'Not set'}`);
        console.log(`   ✅ Active: ${user.is_active !== false ? 'Yes' : 'No'}`);
        console.log(`   📅 Created: ${user.created_at ? new Date(user.created_at).toLocaleString() : 'Unknown'}`);
        console.log(`   🔐 Last Login: ${user.last_login_at ? new Date(user.last_login_at).toLocaleString() : 'Never'}`);
        console.log('');
      });
    }
    
  } catch (error) {
    console.error('❌ Error checking users:', error.message);
  } finally {
    await pool.end();
  }
}

checkUsers();