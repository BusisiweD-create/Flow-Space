const io = require('socket.io-client');

async function testRealtimeFunctionality() {
  console.log('🔧 Testing Real-time Socket.io Functionality...\n');
  
  // First, login to get token
  console.log('🔐 Logging in to get authentication token...');
  const axios = require('axios');
  
  try {
    const loginResponse = await axios.post('http://localhost:8000/api/v1/auth/login', {
      email: 'admin@flowspace.com',
      password: 'Admin123!'
    });
    
    console.log('📊 Login response:', JSON.stringify(loginResponse.data, null, 2));
    const token = loginResponse.data.token;
    console.log('✅ Login successful, token received');
    
    // Connect to Socket.io server
    console.log('🔌 Connecting to Socket.io server...');
    
    const socket = io('http://localhost:8000', {
      auth: {
        token: token
      }
    });
    
    // Test connection events
    socket.on('connect', () => {
      console.log('✅ Socket.io connected successfully!');
      console.log('📡 Socket ID:', socket.id);
      
      // Test emit a simple event
      console.log('📤 Testing emit of user_activity event...');
      socket.emit('user_activity', {
        type: 'test',
        message: 'Testing real-time functionality'
      });
    });
    
    socket.on('connected', (data) => {
      console.log('✅ Server connection confirmed:', data.message);
      console.log('👤 User ID:', data.userId);
      console.log('🎯 User Role:', data.userRole);
    });
    
    socket.on('user_online', (data) => {
      console.log('👥 User online event received:', data);
    });
    
    socket.on('user_offline', (data) => {
      console.log('👥 User offline event received:', data);
    });
    
    socket.on('user_activity_update', (data) => {
      console.log('📊 User activity update received:', data);
    });
    
    socket.on('deliverable_created', (data) => {
      console.log('📋 Deliverable created event received:', data);
    });
    
    socket.on('deliverable_updated', (data) => {
      console.log('📋 Deliverable updated event received:', data);
    });
    
    socket.on('sprint_created', (data) => {
      console.log('🏃 Sprint created event received:', data);
    });
    
    socket.on('notification_received', (data) => {
      console.log('🔔 Notification received:', data);
    });
    
    socket.on('disconnect', (reason) => {
      console.log('❌ Socket disconnected:', reason);
    });
    
    socket.on('error', (error) => {
      console.error('❌ Socket error:', error);
    });
    
    // Keep connection open for testing
    console.log('\n⏰ Keeping connection open for 30 seconds to test real-time events...');
    console.log('💡 Try creating deliverables, sprints, or notifications in the frontend to see real-time events here!\n');
    
    setTimeout(() => {
      console.log('\n🛑 Test completed, disconnecting...');
      socket.disconnect();
      process.exit(0);
    }, 30000);
    
  } catch (error) {
    console.error('❌ Error testing real-time functionality:', error.response?.data || error.message);
    process.exit(1);
  }
}

// Check if axios is available, if not install it
function checkDependencies() {
  try {
    require('axios');
    require('socket.io-client');
    return true;
  } catch (e) {
    console.log('📦 Installing required dependencies...');
    return false;
  }
}

if (checkDependencies()) {
  testRealtimeFunctionality();
} else {
  console.log('❌ Please install dependencies first:');
  console.log('npm install axios socket.io-client');
  process.exit(1);
}