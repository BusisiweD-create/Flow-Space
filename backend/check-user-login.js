// Check user login details
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'flowspace',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

async function checkUser(email) {
  try {
    const result = await pool.query(
      'SELECT id, email, password_hash, name, role, created_at, is_active FROM users WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      console.log(`❌ User not found: ${email}`);
      return;
    }
    
    const user = result.rows[0];
    console.log('\n📋 User Details:');
    console.log(`  ID: ${user.id}`);
    console.log(`  Email: ${user.email}`);
    console.log(`  Name: ${user.name}`);
    console.log(`  Role: ${user.role}`);
    console.log(`  Is Active: ${user.is_active}`);
    console.log(`  Has Password Hash: ${user.password_hash ? 'YES ✅' : 'NO ❌'}`);
    if (user.password_hash) {
      console.log(`  Password Hash (first 20 chars): ${user.password_hash.substring(0, 20)}...`);
    }
    console.log(`  Created At: ${user.created_at}`);
    
    // List all users to see what's available
    console.log('\n📋 All Users in Database:');
    const allUsers = await pool.query('SELECT email, name, role, is_active FROM users ORDER BY created_at DESC LIMIT 10');
    allUsers.rows.forEach((u, i) => {
      console.log(`  ${i + 1}. ${u.email} (${u.name}) - ${u.role} - ${u.is_active ? 'Active' : 'Inactive'}`);
    });
    
  } catch (error) {
    console.error('Error checking user:', error);
  } finally {
    await pool.end();
  }
}

const email = process.argv[2] || 'mabotsaboitumelo5@gmail.com';
checkUser(email);

