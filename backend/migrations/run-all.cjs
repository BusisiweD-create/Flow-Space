const { execSync } = require('child_process');

function run(script) {
  console.log(`\n▶️ Running: ${script}`);
  // Scripts are resolved relative to backend/ (Render runs from backend/)
  execSync(`node ${script}`, { stdio: 'inherit' });
}

try {
  console.log('🚀 Running migrations only');

  // 1. Base tables
  run('create-tables.cjs');

  // 1b. Ensure core tables exist regardless of previous issues
  run('migrations/create_core_tables.cjs');

  // 2. Deliverables + signoff tables
  run('migrations/create_signoff_deliverables_tables.cjs');

  // 3. Fix any schema mismatches used by scheduler/queries
  run('migrations/fix_signoff_schema.cjs');

  // 4. New feature tables
  run('migrations/create_new_features_tables.cjs');

  // 5. Tickets table (critical for sprint management)
  run('migrations/create_tickets_table.cjs');

  // 5b. Complete all tables (alternative to individual migrations)
  // Uncomment the line below to use the complete migration instead
  // run('migrations/create_all_tables.js');

  // 6. Seeds (optional)
  try {
    run('migrations/seed.cjs');
  } catch (e) {
    console.log('⚠️ Seed script failed — continuing deployment');
  }

  console.log('\n🎉 All migrations executed successfully!');
  console.log('✅ Migrations complete');
  process.exit(0); // 🔴 IMPORTANT: Exit cleanly, don't start server
} catch (err) {
  console.error('\n❌ MIGRATION ERROR:', err.message);
  process.exit(1);
}
