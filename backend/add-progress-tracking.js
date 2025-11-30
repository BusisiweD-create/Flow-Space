const pool = require('./db');

async function addProgressTracking() {
  try {
    console.log('🔧 Adding progress tracking to deliverables...');
    
    // Add progress column to deliverables table
    await pool.query(`
      ALTER TABLE deliverables 
      ADD COLUMN IF NOT EXISTS progress DECIMAL(5,2) DEFAULT 0.00 CHECK (progress >= 0 AND progress <= 100)
    `);
    
    console.log('✅ Progress column added to deliverables table');
    
    // Create activity tracking table (without foreign key constraints for now)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS activity_log (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id),
        activity_type VARCHAR(50) NOT NULL,
        activity_title VARCHAR(255) NOT NULL,
        activity_description TEXT,
        deliverable_id VARCHAR(255),
        sprint_id VARCHAR(255),
        metadata JSONB,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    
    console.log('✅ Activity log table created');
    
    // Create indexes for better performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON activity_log(user_id);
    `);
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_activity_log_deliverable_id ON activity_log(deliverable_id);
    `);
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON activity_log(created_at);
    `);
    
    console.log('✅ Indexes created for activity log');
    
    // Update existing deliverables with progress based on status
    await pool.query(`
      UPDATE deliverables 
      SET progress = CASE 
        WHEN status = 'Draft' THEN 0.00
        WHEN status = 'In Progress' THEN 50.00
        WHEN status = 'Review' THEN 80.00
        WHEN status = 'Completed' THEN 100.00
        ELSE 0.00
      END
    `);
    
    console.log('✅ Updated existing deliverables with progress values');
    
    // Insert sample activity log entries
    const userResult = await pool.query('SELECT id FROM users LIMIT 1');
    if (userResult.rows.length > 0) {
      const userId = userResult.rows[0].id;
      
      const sampleActivities = [
        {
          activity_type: 'deliverable_created',
          activity_title: 'Deliverable Created',
          activity_description: 'User Authentication System deliverable was created',
          deliverable_id: null,
        },
        {
          activity_type: 'deliverable_updated',
          activity_title: 'Deliverable Updated',
          activity_description: 'Payment Integration status changed to In Progress',
          deliverable_id: null,
        },
        {
          activity_type: 'deliverable_completed',
          activity_title: 'Deliverable Completed',
          activity_description: 'User Authentication System has been completed',
          deliverable_id: null,
        }
      ];
      
      for (const activity of sampleActivities) {
        await pool.query(`
          INSERT INTO activity_log (user_id, activity_type, activity_title, activity_description, deliverable_id)
          VALUES ($1, $2, $3, $4, $5)
        `, [userId, activity.activity_type, activity.activity_title, activity.activity_description, activity.deliverable_id]);
      }
      
      console.log('✅ Sample activity log entries created');
    }
    
  } catch (error) {
    console.error('❌ Error adding progress tracking:', error);
  } finally {
    await pool.end();
  }
}

addProgressTracking();
