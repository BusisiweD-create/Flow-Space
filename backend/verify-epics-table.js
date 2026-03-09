require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function verifyEpicsTable() {
  try {
    console.log('🔍 Verifying epics table structure...\n');

    // Check if table exists
    const tableCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'epics'
    `);

    if (tableCheck.rows.length === 0) {
      console.log('❌ Epics table does not exist');
      return;
    }

    console.log('✅ Epics table exists');

    // Check table columns
    const columns = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'epics'
      ORDER BY ordinal_position
    `);

    console.log('\n📋 Epics table columns:');
    columns.rows.forEach(row => {
      console.log(`   ✓ ${row.column_name} (${row.data_type}) ${row.is_nullable === 'NO' ? 'NOT NULL' : 'NULLABLE'}`);
    });

    // Check if sprint_epics table exists
    const sprintEpicsCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'sprint_epics'
    `);

    if (sprintEpicsCheck.rows.length > 0) {
      console.log('\n✅ Sprint_epics table exists');
      
      const sprintEpicsColumns = await pool.query(`
        SELECT column_name, data_type
        FROM information_schema.columns 
        WHERE table_name = 'sprint_epics'
        ORDER BY ordinal_position
      `);

      console.log('\n📋 Sprint_epics table columns:');
      sprintEpicsColumns.rows.forEach(row => {
        console.log(`   ✓ ${row.column_name} (${row.data_type})`);
      });
    } else {
      console.log('\n⚠️  Sprint_epics table does not exist');
    }

    // Test inserting a sample epic
    console.log('\n🧪 Testing epic insertion...');
    const testEpic = await pool.query(`
      INSERT INTO epics (title, description, created_by, status)
      VALUES ('Test Epic', 'Test Description', gen_random_uuid(), 'draft')
      RETURNING id, title, status
    `);

    console.log('✅ Test epic created:', testEpic.rows[0]);

    // Clean up test epic
    await pool.query('DELETE FROM epics WHERE id = $1', [testEpic.rows[0].id]);
    console.log('✅ Test epic cleaned up');

    console.log('\n🎉 Epics table verification complete!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

verifyEpicsTable();
