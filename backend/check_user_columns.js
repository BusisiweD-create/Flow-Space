const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'flow_space',
  user: 'postgres',
  password: 'postgres',
});

async function checkUserColumns() {
  try {
    console.log('🔍 Checking user table columns...');
    
    // Get all columns from users table
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Users table columns:');
    console.log('='.repeat(50));
    
    result.rows.forEach((column, index) => {
      console.log(`${index + 1}. ${column.column_name} (${column.data_type}, ${column.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
    // Check specific columns we care about
    const nameColumns = result.rows.filter(col => 
      col.column_name.includes('name') || col.column_name.includes('first') || col.column_name.includes('last')
    );
    
    console.log('\n📝 Name-related columns:');
    console.log('-'.repeat(30));
    nameColumns.forEach(col => {
      console.log(`• ${col.column_name} (${col.data_type})`);
    });
    
  } catch (error) {
    console.error('❌ Error checking columns:', error.message);
  } finally {
    await pool.end();
  }
}

checkUserColumns();