require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function fixEpicsTable() {
  try {
    console.log('🔧 Fixing epics table constraints...\n');

    // Check existing foreign key constraints
    const constraints = await pool.query(`
      SELECT
        tc.constraint_name,
        tc.table_name, 
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name 
      FROM information_schema.table_constraints AS tc 
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'epics'
    `);

    console.log('📋 Existing foreign key constraints on epics table:');
    constraints.rows.forEach(row => {
      console.log(`   ✓ ${row.constraint_name}: ${row.column_name} -> ${row.foreign_table_name}.${row.foreign_column_name}`);
    });

    // Drop the problematic constraint if it exists
    if (constraints.rows.length > 0) {
      for (const constraint of constraints.rows) {
        if (constraint.constraint_name.includes('created_by_fkey')) {
          console.log(`\n🗑️  Dropping constraint: ${constraint.constraint_name}`);
          await pool.query(`ALTER TABLE epics DROP CONSTRAINT ${constraint.constraint_name}`);
          console.log('✅ Constraint dropped');
        }
      }
    }

    // Add a proper constraint if needed
    console.log('\n🔗 Adding proper foreign key constraint (if needed)...');
    try {
      await pool.query(`
        ALTER TABLE epics 
        ADD CONSTRAINT epics_created_by_fkey 
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
      `);
      console.log('✅ Foreign key constraint added');
    } catch (e) {
      console.log('⚠️  Constraint may already exist or table structure is different');
    }

    // Test epic creation with a real user
    console.log('\n🧪 Testing epic creation with real user...');
    
    // Get a real user ID
    const userResult = await pool.query('SELECT id FROM users LIMIT 1');
    if (userResult.rows.length === 0) {
      console.log('❌ No users found in database');
      return;
    }

    const realUserId = userResult.rows[0].id;
    console.log(`✅ Using user ID: ${realUserId}`);

    const testEpic = await pool.query(`
      INSERT INTO epics (title, description, created_by, status)
      VALUES ($1, $2, $3, $4)
      RETURNING id, title, status, created_by
    `, ['Test Epic', 'Test Description', realUserId, 'draft']);

    console.log('✅ Test epic created:', testEpic.rows[0]);

    // Clean up test epic
    await pool.query('DELETE FROM epics WHERE id = $1', [testEpic.rows[0].id]);
    console.log('✅ Test epic cleaned up');

    console.log('\n🎉 Epics table fixed successfully!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

fixEpicsTable();
