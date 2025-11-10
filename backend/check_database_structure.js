const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function checkDatabaseStructure() {
  try {
    console.log('Checking users table structure...');
    const usersResult = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    
    console.log('Users table columns:');
    usersResult.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });
    
    console.log('\nChecking deliverables table structure...');
    const deliverablesResult = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'deliverables' 
      ORDER BY ordinal_position
    `);
    
    console.log('Deliverables table columns:');
    deliverablesResult.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });
    
    console.log('\nChecking sprints table structure...');
    const sprintsResult = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'sprints' 
      ORDER BY ordinal_position
    `);
    
    console.log('Sprints table columns:');
    sprintsResult.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });
    
  } catch (error) {
    console.error('Error checking database structure:', error.message);
  } finally {
    await pool.end();
  }
}

checkDatabaseStructure();