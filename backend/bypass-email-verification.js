const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

async function bypassEmailVerification() {
  try {
    console.log('🔧 Bypassing email verification for existing users...');
    
    // Users to update
    const emails = [
      'dhlamini331@gmail.com',
      'bdhlamini883@gmail.com', 
      'busisiwe.dhlamini@khonology.com'
    ];
    
    for (const email of emails) {
      console.log(`\n🔄 Processing: ${email}`);
      
      // Check if user exists and get current status
      const userResult = await pool.query(
        'SELECT id, email, email_verified, name FROM users WHERE email = $1',
        [email]
      );
      
      if (userResult.rows.length === 0) {
        console.log(`❌ User not found: ${email}`);
        continue;
      }
      
      const user = userResult.rows[0];
      console.log(`📋 Current status for ${user.email}:`);
      console.log(`   Name: ${user.name}`);
      console.log(`   Email Verified: ${user.email_verified}`);
      
      if (!user.email_verified) {
        // Update user to mark email as verified
        await pool.query(
          `UPDATE users 
           SET email_verified = true, 
               email_verified_at = NOW(),
               email_verification_code = NULL,
               email_verification_expires_at = NULL,
               updated_at = NOW()
           WHERE id = $1`,
          [user.id]
        );
        
        console.log(`✅ Email verification bypassed for: ${user.email}`);
      } else {
        console.log(`ℹ️  Email already verified for: ${user.email}`);
      }
    }
    
    console.log('\n📝 Summary - You can now log in with:');
    console.log('   Email: dhlamini331@gmail.com');
    console.log('   Password: Password@1');
    console.log('   ---');
    console.log('   Email: bdhlamini883@gmail.com');
    console.log('   Password: Password@1');
    console.log('   ---');
    console.log('   Email: busisiwe.dhlamini@khonology.com');
    console.log('   Password: Password@1');
    console.log('\n🎉 All users should now be able to log in!');
    
  } catch (error) {
    console.error('❌ Error bypassing email verification:', error);
  } finally {
    await pool.end();
  }
}

bypassEmailVerification();
