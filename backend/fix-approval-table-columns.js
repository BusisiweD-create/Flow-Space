const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

async function fixApprovalTable() {
  try {
    console.log('🔧 Fixing approval_requests table columns...');
    
    // Check if columns need to be renamed/added
    const columnsToAdd = [
      {
        name: 'requested_by',
        type: 'UUID',
        reference: 'REFERENCES users(id) ON DELETE CASCADE'
      },
      {
        name: 'reviewed_by', 
        type: 'UUID',
        reference: 'REFERENCES users(id) ON DELETE SET NULL'
      },
      {
        name: 'title',
        type: 'VARCHAR(255)',
        reference: 'NOT NULL'
      },
      {
        name: 'description',
        type: 'TEXT',
        reference: ''
      },
      {
        name: 'priority',
        type: 'VARCHAR(50)',
        reference: "DEFAULT 'medium'"
      },
      {
        name: 'category',
        type: 'VARCHAR(50)',
        reference: "DEFAULT 'general'"
      },
      {
        name: 'review_reason',
        type: 'TEXT',
        reference: ''
      },
      {
        name: 'deliverable_title',
        type: 'TEXT',
        reference: ''
      },
      {
        name: 'deliverable_description',
        type: 'TEXT',
        reference: ''
      }
    ];
    
    for (const column of columnsToAdd) {
      try {
        await pool.query(`
          ALTER TABLE approval_requests 
          ADD COLUMN IF NOT EXISTS ${column.name} ${column.type} ${column.reference}
        `);
        console.log(`✅ Added column: ${column.name}`);
      } catch (error) {
        console.log(`⚠️  Column ${column.name} might already exist or error:`, error.message);
      }
    }
    
    // Copy data from old columns to new ones if needed
    try {
      await pool.query(`
        UPDATE approval_requests 
        SET requested_by = requester_id 
        WHERE requested_by IS NULL AND requester_id IS NOT NULL
      `);
      console.log('✅ Migrated requester_id to requested_by');
    } catch (error) {
      console.log('⚠️  Migration requester_id to requested_by:', error.message);
    }
    
    try {
      await pool.query(`
        UPDATE approval_requests 
        SET reviewed_by = approver_id 
        WHERE reviewed_by IS NULL AND approver_id IS NOT NULL
      `);
      console.log('✅ Migrated approver_id to reviewed_by');
    } catch (error) {
      console.log('⚠️  Migration approver_id to reviewed_by:', error.message);
    }
    
    // Check final table structure
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'approval_requests' 
      ORDER BY ordinal_position;
    `);
    
    console.log('\n✅ Updated approval_requests table columns:');
    result.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
  } catch (error) {
    console.error('❌ Error fixing approval_requests table:', error);
  } finally {
    await pool.end();
  }
}

fixApprovalTable();
