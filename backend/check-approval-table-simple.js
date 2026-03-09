const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function checkApprovalRequestsTable() {
  try {
    console.log('Checking approval_requests table structure...');
    const result = await pool.query(
      'SELECT column_name, data_type FROM information_schema.columns WHERE table_name = \'approval_requests\' ORDER BY ordinal_position'
    );
    
    console.log('Columns in approval_requests table:');
    result.rows.forEach(row => {
      console.log(`- ${row.column_name} (${row.data_type})`);
    });
    
    // Check if requested_at column exists
    const hasRequestedAt = result.rows.some(row => row.column_name === 'requested_at');
    const hasCreatedAt = result.rows.some(row => row.column_name === 'created_at');
    
    console.log(`Has requested_at column: ${hasRequestedAt}`);
    console.log(`Has created_at column: ${hasCreatedAt}`);
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error);
  }
}

checkApprovalRequestsTable();
