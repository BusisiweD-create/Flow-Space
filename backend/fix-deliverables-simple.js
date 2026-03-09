require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function fixDeliverablesTable() {
  try {
    console.log('🔧 Fixing deliverables table structure...\n');

    // Check current columns
    const columns = await pool.query(`
      SELECT column_name, data_type
      FROM information_schema.columns 
      WHERE table_name = 'deliverables'
      ORDER BY ordinal_position
    `);

    console.log('📋 Current deliverables table columns:');
    columns.rows.forEach(row => {
      console.log(`   ✓ ${row.column_name} (${row.data_type})`);
    });

    // Check if priority column exists
    const hasPriority = columns.rows.some(row => row.column_name === 'priority');
    
    if (!hasPriority) {
      console.log('\n➕ Adding missing priority column...');
      await pool.query(`ALTER TABLE deliverables ADD COLUMN priority VARCHAR(20) DEFAULT 'Medium'`);
      console.log('✅ Priority column added');
    } else {
      console.log('\n✅ Priority column already exists');
    }

    // Check for other missing columns
    const requiredColumns = [
      { name: 'sprint_ids', type: 'UUID[]', default: "'{}'::uuid[]" },
      { name: 'project_id', type: 'UUID', default: 'NULL' },
      { name: 'created_by', type: 'UUID', default: 'NULL' },
      { name: 'updated_at', type: 'TIMESTAMP', default: 'NOW()' }
    ];

    for (const col of requiredColumns) {
      const exists = columns.rows.some(row => row.column_name === col.name);
      if (!exists) {
        console.log(`\n➕ Adding missing ${col.name} column...`);
        const defaultClause = col.default ? ` DEFAULT ${col.default}` : '';
        await pool.query(`ALTER TABLE deliverables ADD COLUMN ${col.name} ${col.type}${defaultClause}`);
        console.log(`✅ ${col.name} column added`);
      } else {
        console.log(`✅ ${col.name} column already exists`);
      }
    }

    // Test deliverable creation
    console.log('\n🧪 Testing deliverable creation...');
    
    // Get a real user ID
    const userResult = await pool.query('SELECT id FROM users LIMIT 1');
    if (userResult.rows.length === 0) {
      console.log('❌ No users found in database');
      return;
    }

    const realUserId = userResult.rows[0].id;
    console.log(`✅ Using user ID: ${realUserId}`);

    const testDeliverable = await pool.query(`
      INSERT INTO deliverables (title, description, priority, status, created_by)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, title, priority, status, created_by
    `, ['Test Deliverable', 'Test Description', 'Medium', 'Draft', realUserId]);

    console.log('✅ Test deliverable created:', testDeliverable.rows[0]);

    // Clean up test deliverable
    await pool.query('DELETE FROM deliverables WHERE id = $1', [testDeliverable.rows[0].id]);
    console.log('✅ Test deliverable cleaned up');

    console.log('\n🎉 Deliverables table fixed successfully!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

fixDeliverablesTable();
