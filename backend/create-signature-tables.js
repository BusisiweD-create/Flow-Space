/**
 * Create Digital Signatures Tables
 * Run this to create the digital_signatures and docusign_envelopes tables
 * 
 * Usage: node create-signature-tables.js
 */

require('dotenv').config();
const { Pool } = require('pg');
const dbConfig = require('./database-config');
const fs = require('fs');
const path = require('path');

console.log('🔧 Creating Digital Signatures Tables...\n');

const pool = new Pool(dbConfig);

async function createTables() {
  const client = await pool.connect();
  
  try {
    console.log('📋 Reading SQL file...');
    const sqlFilePath = path.join(__dirname, 'database', 'create_signature_tables.sql');
    const sql = fs.readFileSync(sqlFilePath, 'utf8');
    
    console.log('🔨 Executing SQL...');
    await client.query(sql);
    
    console.log('✅ Digital signatures tables created successfully!');
    
    // Verify tables exist
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('digital_signatures', 'docusign_envelopes')
      ORDER BY table_name
    `);
    
    console.log('\n📊 Tables created:');
    result.rows.forEach(row => {
      console.log(`   ✓ ${row.table_name}`);
    });
    
    console.log('\n🎉 Setup complete! Your signature system is ready.');
    
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

createTables().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

