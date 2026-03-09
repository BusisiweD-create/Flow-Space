// ES Module wrapper for CommonJS migration script
import { execSync } from 'child_process';

try {
  console.log('🚀 Running migrations (ES Module wrapper)...');
  
  // Run the actual CommonJS migration script
  execSync('node migrations/run-all.cjs', { stdio: 'inherit' });
  
  console.log('✅ Migration wrapper completed successfully');
} catch (err) {
  console.error('❌ Migration wrapper failed:', err.message);
  process.exit(1);
}
