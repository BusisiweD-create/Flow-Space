// Script to check existing users in production database
import pkg from 'pg';
const { Pool } = pkg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkUsers() {
  try {
    console.log('🔍 Checking existing users in production database...');
    
    const result = await pool.query(`
      SELECT email, name, role, is_active, email_verified, created_at 
      FROM users 
      ORDER BY created_at DESC
    `);
    
    if (result.rows.length === 0) {
      console.log('📭 No users found in database');
    } else {
      console.log(`👥 Found ${result.rows.length} user(s):`);
      result.rows.forEach((user, index) => {
        console.log(`\n${index + 1}. 📧 Email: ${user.email}`);
        console.log(`   👤 Name: ${user.name}`);
        console.log(`   🔐 Role: ${user.role}`);
        console.log(`   ✅ Active: ${user.is_active}`);
        console.log(`   📧 Verified: ${user.email_verified}`);
        console.log(`   📅 Created: ${user.created_at}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error checking users:', error.message);
  } finally {
    await pool.end();
  }
}

checkUsers();
