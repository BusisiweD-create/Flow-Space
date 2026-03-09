// Database seeding script for production users
import pkg from 'pg';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';

dotenv.config();

const { Pool } = pkg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false,
});

async function seedUsers() {
  console.log('🌱 Starting user seeding...');
  
  try {
    // Check if users already exist
    const existingUsers = await pool.query(
      'SELECT email FROM users WHERE email ILIKE $1',
      ['thabang.nkabinde@khonology.com']
    );

    if (existingUsers.rows.length > 0) {
      console.log('✅ User thabang.nkabinde@khonology.com already exists');
      return;
    }

    // Create test users if they don't exist
    const testUsers = [
      {
        email: 'thabang.nkabinde@khonology.com',
        name: 'Thabang Nkabinde',
        password: 'Password@1',
        role: 'admin'
      },
      {
        email: 'busisiwe.dhlamini@khonology.com', 
        name: 'Busisiwe Dhlamini',
        password: 'Password@1',
        role: 'admin'
      }
    ];

    for (const user of testUsers) {
      const hashedPassword = await bcrypt.hash(user.password, 12);
      
      await pool.query(
        `INSERT INTO users (email, name, password_hash, role, is_active, created_at) 
         VALUES ($1, $2, $3, $4, $5, NOW())`,
        [user.email.toLowerCase().trim(), user.name, hashedPassword, user.role, true]
      );
      
      console.log(`✅ Created user: ${user.email}`);
    }

    console.log('🎉 User seeding completed successfully!');
    
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
  } finally {
    await pool.end();
  }
}

seedUsers();
