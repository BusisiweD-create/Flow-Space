const Service = require('node-windows').Service;

// Get the absolute path to the server-robust.js file
const scriptPath = require('path').join(__dirname, 'server-robust.js');

// Create a new service object
const svc = new Service({
  name: 'FlowSpaceBackend', // name shown in Windows Services
  description: 'Flow-Space Node.js Backend Server running permanently in the background',
  script: scriptPath,
  nodeOptions: [
    '--harmony',
    '--max_old_space_size=4096'
  ]
});

// Listen for the "install" event, which indicates the process is ready
svc.on('install', () => {
  console.log('✅ Service installed successfully. Starting service...');
  svc.start();
});

svc.on('alreadyinstalled', () => {
  console.log('ℹ️ Service is already installed. You can start it via services.msc or run `node start-service.js` to ensure it is running.');
});

svc.on('start', () => {
  console.log('🚀 Flow-Space Backend Server is now running permanently in the background!');
  console.log('📊 Health check: http://localhost:3000/health');
});

svc.on('stop', () => {
  console.log('🛑 Flow-Space Backend Server service stopped.');
});

svc.on('error', (err) => {
  console.error('❌ Service encountered an error:', err);
});

// Install the service
console.log('Attempting to install FlowSpaceBackend service...');
svc.install();
