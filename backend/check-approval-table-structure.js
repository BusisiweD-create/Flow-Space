const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

async function checkApprovalTableStructure() {
  try {
    console.log('🔍 Checking approval_requests table structure...');
    
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'approval_requests' 
      ORDER BY ordinal_position;
    `);
    
    if (result.rows.length === 0) {
      console.log('❌ approval_requests table does not exist');
    } else {
      console.log('✅ approval_requests table columns:');
      result.rows.forEach(row => {
        console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error checking approval_requests table:', error);
  } finally {
    await pool.end();
  }
}

checkApprovalTableStructure();
