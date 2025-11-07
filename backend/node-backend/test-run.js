const { spawn } = require('child_process');

console.log('Starting application...');

const child = spawn('node', ['src/app.js'], {
  stdio: ['pipe', 'pipe', 'pipe']
});

child.stdout.on('data', (data) => {
  console.log('STDOUT:', data.toString());
});

child.stderr.on('data', (data) => {
  console.error('STDERR:', data.toString());
});

child.on('close', (code) => {
  console.log(`Process exited with code ${code}`);
});