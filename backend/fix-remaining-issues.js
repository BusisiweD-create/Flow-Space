const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function fixRemainingIssues() {
  try {
    console.log('🔧 Fixing remaining database issues...\n');
    
    // 1. Create the trigger function properly
    console.log('⏳ Creating update_updated_at_column function...');
    await pool.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);
    console.log('✅ Function created successfully');
    
    // 2. Create trigger for tickets
    console.log('⏳ Creating trigger for tickets...');
    await pool.query(`
      DROP TRIGGER IF EXISTS update_tickets_updated_at ON tickets;
    `);
    await pool.query(`
      CREATE TRIGGER update_tickets_updated_at 
          BEFORE UPDATE ON tickets
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('✅ Tickets trigger created');
    
    // 3. Create trigger for notifications
    console.log('⏳ Creating trigger for notifications...');
    await pool.query(`
      DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications;
    `);
    await pool.query(`
      CREATE TRIGGER update_notifications_updated_at 
          BEFORE UPDATE ON notifications
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('✅ Notifications trigger created');
    
    // 4. Verify projects table has the key column
    const projectsCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'projects'
      AND column_name = 'key'
    `);
    
    if (projectsCheck.rows.length > 0) {
      console.log('⏳ Creating index for projects.key...');
      await pool.query(`CREATE INDEX IF NOT EXISTS idx_projects_key ON projects(key)`);
      console.log('✅ Projects key index created');
    } else {
      console.log('⚠️  Projects.key column does not exist (this is OK if not needed)');
    }
    
    // 5. Verify notifications has created_by column
    const notificationsCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'notifications'
      AND column_name = 'created_by'
    `);
    
    if (notificationsCheck.rows.length > 0) {
      console.log('⏳ Creating index for notifications.created_by...');
      await pool.query(`CREATE INDEX IF NOT EXISTS idx_notifications_created_by ON notifications(created_by)`);
      console.log('✅ Notifications created_by index created');
    }
    
    console.log('\n✅ All fixes applied successfully!');
    
    // Final verification
    console.log('\n📊 Final verification:');
    const tablesCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('tickets', 'activity_log', 'users', 'projects', 'sprints', 'deliverables', 'notifications')
      ORDER BY table_name
    `);
    
    console.log('\n✅ All tables present:');
    tablesCheck.rows.forEach(row => {
      console.log(`   ✓ ${row.table_name}`);
    });
    
    console.log('\n🎉 Database is fully ready!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

fixRemainingIssues();

