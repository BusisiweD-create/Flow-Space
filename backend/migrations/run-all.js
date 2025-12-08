const { execSync } = require('child_process');

function run(script) {
  console.log(`\n▶️ Running: ${script}`);
  // Scripts are resolved relative to backend/ (Render runs from backend/)
  execSync(`node ${script}`, { stdio: 'inherit' });
}

try {
  // 1. Base tables
  run('create-tables.js');

  // 1b. Ensure core tables exist regardless of previous issues
  run('migrations/create_core_tables.js');

  // 2. Deliverables + signoff tables
  run('migrations/create_signoff_deliverables_tables.js');

  // 3. Fix any schema mismatches used by scheduler/queries
  run('migrations/fix_signoff_schema.js');

  // 4. New feature tables
  run('migrations/create_new_features_tables.js');

  // 5. Seeds (optional)
  try {
    run('migrations/seed.js');
  } catch (e) {
    console.log('⚠️ Seed script failed — continuing deployment');
  }

  console.log('\n🎉 All migrations executed successfully!');
  console.log('🚀 Starting server...');
  execSync('node server.js', { stdio: 'inherit' });
} catch (err) {
  console.error('\n❌ MIGRATION ERROR:', err.message);
  process.exit(1);
}
