const Service = require('node-windows').Service;

// Create a new service object
const svc = new Service({
  name: 'FlowSpaceBackend'
});

// Listen for the "start" event
svc.on('start', () => {
  console.log('🚀 Flow-Space Backend Server service started!');
  console.log('📊 Health check: http://localhost:3000/health');
});

svc.on('stop', () => {
  console.log('🛑 Flow-Space Backend Server service stopped.');
});

svc.on('error', (err) => {
  console.error('❌ Service error:', err);
});

// Start the service
console.log('Starting FlowSpaceBackend service...');
svc.start();
