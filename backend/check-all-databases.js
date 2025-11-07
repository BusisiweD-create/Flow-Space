// Check all databases on PostgreSQL server - simplified
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'postgres', // Connect to default postgres database
  password: 'postgres',
  port: 5432,
});

async function checkDatabases() {
  try {
    console.log('🔍 Checking all databases on your PostgreSQL server...\n');
    
    // List all databases
    const result = await pool.query(`
      SELECT datname
      FROM pg_database 
      WHERE datistemplate = false
      ORDER BY datname
    `);
    
    console.log(`📊 Found ${result.rows.length} databases:\n`);
    
    result.rows.forEach((db, index) => {
      console.log(`${index + 1}. 🗄️ Database: ${db.datname}`);
    });
    console.log('');
    
    // Check if there are any other databases that might contain user data
    const flowSpaceDbs = result.rows.filter(row => 
      row.datname.toLowerCase().includes('flow') || 
      row.datname.toLowerCase().includes('space') ||
      row.datname.toLowerCase().includes('user') ||
      row.datname.toLowerCase().includes('app')
    );
    
    if (flowSpaceDbs.length > 0) {
      console.log('🎯 Found databases that might contain Flow-Space data:');
      flowSpaceDbs.forEach(db => {
        console.log(`   - ${db.datname}`);
      });
      console.log('');
    }
    
    // Check each database for users table
    console.log('🔍 Checking each database for users table...\n');
    
    for (const db of result.rows) {
      if (db.datname === 'postgres') continue; // Skip default postgres db
      
      try {
        const dbPool = new Pool({
          user: 'postgres',
          host: 'localhost',
          database: db.datname,
          password: 'postgres',
          port: 5432,
        });
        
        const userCheck = await dbPool.query(`
          SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'users'
          );
        `);
        
        if (userCheck.rows[0].exists) {
          const userCount = await dbPool.query('SELECT COUNT(*) as count FROM users');
          console.log(`✅ ${db.datname}: Has users table with ${userCount.rows[0].count} users`);
          
          // Get sample users
          const sampleUsers = await dbPool.query(`
            SELECT email, name, role, created_at 
            FROM users 
            ORDER BY created_at DESC 
            LIMIT 3
          `);
          
          sampleUsers.rows.forEach(user => {
            console.log(`   👤 ${user.email} (${user.name}) - ${user.role}`);
          });
          console.log('');
        } else {
          console.log(`❌ ${db.datname}: No users table`);
        }
        
        await dbPool.end();
      } catch (error) {
        console.log(`⚠️  ${db.datname}: Error checking - ${error.message}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error checking databases:', error.message);
  } finally {
    await pool.end();
  }
}

checkDatabases();