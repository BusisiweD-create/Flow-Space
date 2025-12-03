const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function verifyDatabase() {
  try {
    console.log('🔍 Verifying Flow-Space Database Structure\n');
    console.log('=' .repeat(60));
    
    const tables = ['users', 'projects', 'sprints', 'deliverables', 'tickets', 'notifications', 'activity_log'];
    
    for (const table of tables) {
      console.log(`\n📋 ${table.toUpperCase()} table:`);
      
      const result = await pool.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = $1 
        ORDER BY ordinal_position
      `, [table]);
      
      result.rows.forEach(row => {
        const nullable = row.is_nullable === 'YES' ? '(nullable)' : '(NOT NULL)';
        const defaultVal = row.column_default ? `[default: ${row.column_default.substring(0, 30)}...]` : '';
        console.log(`   • ${row.column_name.padEnd(25)} ${row.data_type.padEnd(20)} ${nullable} ${defaultVal}`);
      });
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ Database verification complete!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

verifyDatabase();

