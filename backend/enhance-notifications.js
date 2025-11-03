const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

async function enhanceNotifications() {
  try {
    console.log('Enhancing notifications system...');
    
    // Add sample notifications for testing
    const sampleNotifications = [
      {
        title: 'Welcome to Flow-Space!',
        message: 'Your notifications are now working perfectly. You can manage projects, sprints, and tickets with real-time updates.',
        type: 'info',
        user_id: null, // General notification for all users
        created_by: null,
        is_read: false,
      },
      {
        title: 'Sprint Status Updated',
        message: 'Sprint "Sprint 6" status has been changed to "planning"',
        type: 'sprint_update',
        user_id: null,
        created_by: null,
        is_read: false,
      },
      {
        title: 'Ticket Moved',
        message: 'Ticket TICK-1760541100611 has been moved to "In Review"',
        type: 'ticket_update',
        user_id: null,
        created_by: null,
        is_read: false,
      },
      {
        title: 'Project Created',
        message: 'New project "Deliverables Hub" has been created successfully',
        type: 'project_created',
        user_id: null,
        created_by: null,
        is_read: false,
      },
      {
        title: 'System Maintenance',
        message: 'Scheduled maintenance will occur tonight from 2 AM to 4 AM. Some features may be temporarily unavailable.',
        type: 'system',
        user_id: null,
        created_by: null,
        is_read: true,
      }
    ];

    // Insert sample notifications
    for (const notification of sampleNotifications) {
      await pool.query(`
        INSERT INTO notifications (title, message, type, user_id, created_by, is_read, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      `, [
        notification.title,
        notification.message,
        notification.type,
        notification.user_id,
        notification.created_by,
        notification.is_read
      ]);
    }

    console.log('✅ Sample notifications inserted successfully');
    
    // Add notification types enum for better organization
    await pool.query(`
      DO $$ BEGIN
        CREATE TYPE notification_type AS ENUM (
          'info', 
          'sprint_update', 
          'ticket_update', 
          'project_created', 
          'system', 
          'warning', 
          'success'
        );
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    console.log('✅ Notification types enum created');
    
    // Add indexes for better performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
    `);
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_created_at_desc ON notifications(created_at DESC);
    `);

    console.log('✅ Performance indexes created');
    
    // Create a function to get unread count for a user
    await pool.query(`
      CREATE OR REPLACE FUNCTION get_unread_notification_count(user_uuid UUID)
      RETURNS INTEGER AS $$
      BEGIN
        RETURN (
          SELECT COUNT(*)
          FROM notifications
          WHERE (user_id = user_uuid OR user_id IS NULL)
          AND is_read = false
        );
      END;
      $$ LANGUAGE plpgsql;
    `);

    console.log('✅ Unread count function created');
    
    // Test the function
    const testResult = await pool.query(`
      SELECT get_unread_notification_count('80ebe775-1837-4ff5-a0a5-faabd46e0b96'::UUID) as unread_count;
    `);
    
    console.log(`✅ Test unread count: ${testResult.rows[0].unread_count}`);
    
  } catch (error) {
    console.error('❌ Error enhancing notifications:', error);
  } finally {
    await pool.end();
  }
}

enhanceNotifications();
