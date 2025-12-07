const { sequelize } = require('./src/config/database');

async function clearAllUsers() {
  try {
    console.log('🗑️  Clearing all users from database...');
    
    // Test database connection first
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Delete all users
    const [result, metadata] = await sequelize.query('DELETE FROM users');
    
    console.log(`✅ Successfully deleted ${result} user(s) from the database`);
    
    // Reset auto-increment if using SQLite (though SQLite doesn't auto-increment UUIDs)
    try {
      await sequelize.query('DELETE FROM sqlite_sequence WHERE name="users"');
      console.log('✅ Reset user table sequence');
    } catch (seqError) {
      console.log('ℹ️  No sequence to reset (not needed for UUID primary keys)');
    }
    
    console.log('\n🎉 Database is now empty. You can register new users.');
    
  } catch (error) {
    console.error('❌ Error clearing users:', error.message);
    
    if (error.message.includes('no such table')) {
      console.log('\n💡 The users table does not exist yet.');
      console.log('   You can proceed with registration - the table will be created automatically.');
    }
  } finally {
    await sequelize.close();
  }
}

// Run the function
clearAllUsers();