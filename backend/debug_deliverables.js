
import pg from 'pg';
import { fileURLToPath } from 'url';
import path from 'path';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config({ path: path.join(__dirname, '.env') });
// Also try .env.sit if .env is missing or doesn't have DB url
dotenv.config({ path: path.join(__dirname, '.env.sit') });

const pools = [
  { name: 'flow_space', config: { user: process.env.DB_USER || 'postgres', host: process.env.DB_HOST || 'localhost', database: 'flow_space', password: process.env.DB_PASSWORD || 'postgres', port: process.env.DB_PORT || 5432 } }
];

async function checkData() {
  for (const item of pools) {
    console.log(`\n=== CHECKING DATABASE: ${item.name} ===`);
    const pool = new pg.Pool(item.config);
    try {
      // Test connection
      await pool.query('SELECT 1');
      console.log('✅ Connected successfully');
      
      console.log('--- USER SCHEMA ---');
      const userSchema = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'id'");
      console.log('User ID Type:', userSchema.rows[0].data_type);

      console.log('--- DELIVERABLES SCHEMA ---');
      const delSchema = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'deliverables' AND column_name IN ('created_by', 'assigned_to')");
      console.table(delSchema.rows);

      console.log('--- FIND THABANG ---');
      const thabang = await pool.query("SELECT id, email, role FROM users WHERE email ILIKE '%Thabang%'");
      console.table(thabang.rows);

      console.log('--- TEST BAD JOIN ---');
       try {
         // This should fail if my hypothesis is correct
         await pool.query(`
           SELECT d.id, d.title, u.email 
           FROM deliverables d 
           LEFT JOIN users u ON d.created_by = u.id 
           LIMIT 5
         `);
         console.log('✅ Standard JOIN worked (Unexpected!)');
       } catch (e) {
         console.log('❌ Standard JOIN failed as expected:', e.message);
       }

       console.log('--- TEST CAST JOIN ---');
       try {
         // This should succeed
         const res = await pool.query(`
           SELECT d.id, d.title, u.email 
           FROM deliverables d 
           LEFT JOIN users u ON d.created_by = CAST(u.id AS TEXT) 
           LIMIT 5
         `);
         console.log(`✅ Cast JOIN worked! Found ${res.rowCount} rows.`);
       } catch (e) {
         console.log('❌ Cast JOIN failed:', e.message);
       }

    } catch (err) {
      console.log(`❌ Failed to connect or query: ${err.message}`);
    } finally {
      await pool.end();
    }
  }
}

checkData();
