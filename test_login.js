const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database path
const dbPath = path.join(__dirname, 'backend', 'hackathon-backend', 'hackathon.db');

// Create database connection
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
  if (err) {
    console.error('❌ Error opening database:', err.message);
    return;
  }
  console.log('✅ Database connection established successfully.');

  // Find the user we just created
  const email = 'Thabang.Nkabinde@khonology.com';
  db.get('SELECT * FROM users WHERE email = ?', [email], (err, row) => {
    if (err) {
      console.error('❌ Error querying database:', err.message);
      db.close();
      return;
    }

    if (row) {
      console.log('✅ User found in database:');
      console.log(`   ID: ${row.id}`);
      console.log(`   Email: ${row.email}`);
      console.log(`   First Name: ${row.firstName}`);
      console.log(`   Last Name: ${row.lastName}`);
      console.log(`   Company: ${row.company}`);
      console.log(`   Role: ${row.role}`);
      console.log(`   Created: ${row.createdAt}`);
      console.log(`   Updated: ${row.updatedAt}`);
      
      // Test login by checking if password exists
      if (row.password) {
        console.log('✅ User has a password set (ready for login)');
      } else {
        console.log('❌ User has no password set');
      }
    } else {
      console.log('❌ User not found in database');
    }

    db.close();
  });
});