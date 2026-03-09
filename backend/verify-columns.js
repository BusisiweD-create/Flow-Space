const { Pool } = require('pg');
require('dotenv').config();

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });

async function checkColumns() {
  try {
    console.log('🔍 Checking critical table columns...\n');
    
    // Check notifications table for updated_at column
    const notificationsColumns = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'notifications'
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Notifications table columns:');
    notificationsColumns.rows.forEach(row => {
      console.log(`   ${row.column_name} (${row.data_type})`);
    });
    
    // Check deliverables table for sprint_id column
    const deliverablesColumns = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'deliverables'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Deliverables table columns:');
    deliverablesColumns.rows.forEach(row => {
      console.log(`   ${row.column_name} (${row.data_type})`);
    });
    
    // Check repository_files table exists and has proper columns
    const repoFilesColumns = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'repository_files'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Repository Files table columns:');
    repoFilesColumns.rows.forEach(row => {
      console.log(`   ${row.column_name} (${row.data_type})`);
    });
    
    // Check epics table exists and has proper columns
    const epicsColumns = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'epics'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Epics table columns:');
    epicsColumns.rows.forEach(row => {
      console.log(`   ${row.column_name} (${row.data_type})`);
    });
    
    console.log('\n🎯 Checking for critical missing columns:');
    
    // Check for specific columns that were missing
    const notificationHasUpdatedAt = notificationsColumns.rows.some(col => col.column_name === 'updated_at');
    console.log(`   ${notificationHasUpdatedAt ? '✅' : '❌'} notifications.updated_at`);
    
    const deliverableHasSprintId = deliverablesColumns.rows.some(col => col.column_name === 'sprint_id');
    console.log(`   ${deliverableHasSprintId ? '✅' : '❌'} deliverables.sprint_id`);
    
    const repoFilesHasDescription = repoFilesColumns.rows.some(col => col.column_name === 'description');
    console.log(`   ${repoFilesHasDescription ? '✅' : '❌'} repository_files.description`);
    
    const epicsHasStatus = epicsColumns.rows.some(col => col.column_name === 'status');
    console.log(`   ${epicsHasStatus ? '✅' : '❌'} epics.status`);
    
  } catch (error) {
    console.error('❌ Error checking columns:', error);
  } finally {
    await pool.end();
  }
}

checkColumns();
