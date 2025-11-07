const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Path to the database file
const dbPath = path.join(__dirname, 'hackathon.db');

// Create database connection
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
  if (err) {
    console.error('Error opening database:', err.message);
    return;
  }
  console.log('Connected to the SQLite database.');
});

// Function to get all tables in the database
function getTables() {
  return new Promise((resolve, reject) => {
    db.all("SELECT name FROM sqlite_master WHERE type='table'", (err, rows) => {
      if (err) {
        reject(err);
      } else {
        resolve(rows.map(row => row.name));
      }
    });
  });
}

// Function to get data from a table
function getTableData(tableName) {
  return new Promise((resolve, reject) => {
    db.all(`SELECT * FROM ${tableName}`, (err, rows) => {
      if (err) {
        reject(err);
      } else {
        resolve(rows);
      }
    });
  });
}

// Main function to read user data
async function readUserData() {
  try {
    // Get all tables
    const tables = await getTables();
    console.log('Tables in database:', tables);
    
    // Look for user-related tables
    const userTables = tables.filter(table => 
      table.toLowerCase().includes('user') || 
      table.toLowerCase().includes('auth') ||
      table.toLowerCase().includes('account')
    );
    
    console.log('\nUser-related tables found:', userTables);
    
    // Read data from user tables
    for (const table of userTables) {
      console.log(`\n=== Data from ${table} table ===`);
      try {
        const data = await getTableData(table);
        console.log(JSON.stringify(data, null, 2));
      } catch (error) {
        console.log(`Error reading ${table}:`, error.message);
      }
    }
    
    // If no user tables found, check all tables for user data
    if (userTables.length === 0) {
      console.log('\nNo user-specific tables found. Checking all tables for user data...');
      
      for (const table of tables) {
        console.log(`\n=== Checking ${table} table ===`);
        try {
          const data = await getTableData(table);
          // Look for any data that might contain user information
          const userData = data.filter(item => 
            item.email || item.username || item.name || item.password
          );
          
          if (userData.length > 0) {
            console.log('Potential user data found:');
            console.log(JSON.stringify(userData, null, 2));
          } else {
            console.log('No obvious user data in this table');
          }
        } catch (error) {
          console.log(`Error reading ${table}:`, error.message);
        }
      }
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    // Close the database connection
    db.close((err) => {
      if (err) {
        console.error('Error closing database:', err.message);
      } else {
        console.log('Database connection closed.');
      }
    });
  }
}

// Run the script
readUserData();