import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  host: 'localhost',
  user: 'postgres', 
  password: 'postgres',
  database: 'flow_space',
  port: 5432,
});

async function listAllUsers() {
  try {
    console.log('Listing all registered users and their roles...\n');
    
    // Get table columns
    const columns = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users'
    `);
    console.log('Columns:', columns.rows.map(r => r.column_name).join(', '));
    
    // Get all users ordered by registration date
    const result = await pool.query(`
      SELECT *
      FROM users 
      ORDER BY created_at DESC
    `);
    
    if (result.rows.length > 0) {
      console.log(`📋 Total Users: ${result.rows.length}\n`);
      
      // Count roles
      const roleCounts = {};
      result.rows.forEach(user => {
        roleCounts[user.role] = (roleCounts[user.role] || 0) + 1;
      });
      
      console.log('👥 Role Distribution:');
      Object.entries(roleCounts).forEach(([role, count]) => {
        console.log(`   ${role}: ${count} user(s)`);
      });
      
      console.log('\n👤 User Details:');
      console.log('='.repeat(80));
      
      result.rows.forEach((user, index) => {
        const fullName = [user.first_name, user.last_name].filter(Boolean).join(' ') || 'No Name';
        console.log(`\n${index + 1}. ${fullName}`);
        console.log('   Email:', user.email);
        console.log('   Role:', user.role);
        console.log('   User ID:', user.id);
        console.log('   Registered:', new Date(user.created_at).toLocaleString());
        console.log('-'.repeat(40));
      });
      
    } else {
      console.log('❌ No users found in the database');
    }
    
  } catch (error) {
    console.error('Error listing users:', error.message);
  } finally {
    await pool.end();
  }
}

listAllUsers();