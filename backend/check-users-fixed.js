const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Path to the SQLite database
const dbPath = path.join(__dirname, 'hackathon-backend', 'hackathon.db');

console.log('📊 Checking users in database...');
console.log(`Database path: ${dbPath}`);

// Open the database
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Error opening database:', err.message);
    return;
  }
  
  console.log('✅ Connected to SQLite database');
  
  // Check if users table exists
  db.get("SELECT name FROM sqlite_master WHERE type='table' AND name='users'", (err, row) => {
    if (err) {
      console.error('❌ Error checking for users table:', err.message);
      db.close();
      return;
    }
    
    if (!row) {
      console.log('❌ Users table does not exist');
      db.close();
      return;
    }
    
    console.log('✅ Users table exists');
    
    // Get all users
    db.all("SELECT * FROM users", (err, rows) => {
      if (err) {
        console.error('❌ Error fetching users:', err.message);
        db.close();
        return;
      }
      
      console.log(`\n📋 Found ${rows.length} user(s):`);
      console.log('='.repeat(80));
      
      rows.forEach((user, index) => {
        console.log(`\n👤 User ${index + 1}:`);
        console.log(`   ID: ${user.id}`);
        console.log(`   Email: ${user.email}`);
        console.log(`   First Name: ${user.first_name || 'N/A'}`);
        console.log(`   Last Name: ${user.last_name || 'N/A'}`);
        console.log(`   Role: ${user.role || 'N/A'}`);
        console.log(`   Created: ${user.created_at || 'N/A'}`);
        console.log(`   Updated: ${user.updated_at || 'N/A'}`);
      });
      
      console.log('\n' + '='.repeat(80));
      db.close();
    });
  });
});