const { Pool } = require('pg');
require('dotenv').config();

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });

async function checkTables() {
  try {
    console.log('🔍 Checking database tables...\n');
    
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('📋 Tables found:');
    result.rows.forEach((row, index) => {
      console.log(`   ${index + 1}. ${row.table_name}`);
    });
    
    console.log(`\n✅ Total tables: ${result.rows.length}`);
    
    // Check specific important tables
    const importantTables = ['users', 'projects', 'deliverables', 'sprints', 'notifications', 'repository_files', 'epics'];
    const foundTables = result.rows.map(row => row.table_name);
    
    console.log('\n🎯 Checking important tables:');
    importantTables.forEach(table => {
      const exists = foundTables.includes(table);
      console.log(`   ${exists ? '✅' : '❌'} ${table}`);
    });
    
  } catch (error) {
    console.error('❌ Error checking tables:', error);
  } finally {
    await pool.end();
  }
}

checkTables();
