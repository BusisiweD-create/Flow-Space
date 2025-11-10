const io = require('socket.io-client');

async function testSocketConnection() {
  console.log('🔌 Testing Socket.io connection to backend...\n');
  
  try {
    // First, login to get a valid token
    console.log('🔐 Logging in to get authentication token...');
    const axios = require('axios');
    
    const loginResponse = await axios.post('http://127.0.0.1:8000/api/v1/auth/login', {
      email: 'Thabang.Nkabinde@khonology.com',
      password: 'Admin123!'
    });
    
    console.log('✅ Login successful!');
    const token = loginResponse.data.token;
    console.log('📋 Token received:', token.substring(0, 20) + '...');
    
    // Connect to Socket.io server with the token
    console.log('\n🔌 Connecting to Socket.io server...');
    
    const socket = io('http://127.0.0.1:8000', {
      auth: {
        token: token
      }
    });
    
    // Set up event handlers
    socket.on('connect', () => {
      console.log('✅ Connected to Socket.io server!');
      console.log('📡 Socket ID:', socket.id);
    });
    
    socket.on('connected', (data) => {
      console.log('✅ Server connection confirmed:', data.message);
      console.log('👤 User ID:', data.userId);
      console.log('🎯 User Role:', data.userRole);
    });
    
    socket.on('connect_error', (error) => {
      console.log('❌ Connection error:', error.message);
    });
    
    socket.on('error', (error) => {
      console.log('❌ Socket error:', error);
    });
    
    socket.on('disconnect', (reason) => {
      console.log('❌ Disconnected:', reason);
    });
    
    // Test connection for 10 seconds
    console.log('\n⏰ Testing connection for 10 seconds...');
    
    setTimeout(() => {
      console.log('\n🛑 Test completed, disconnecting...');
      socket.disconnect();
      process.exit(0);
    }, 10000);
    
  } catch (error) {
    console.error('❌ Error testing Socket.io connection:', error.response?.data || error.message);
    process.exit(1);
  }
}

// Check if axios is available
function checkDependencies() {
  try {
    require('axios');
    require('socket.io-client');
    return true;
  } catch (e) {
    console.log('❌ Required dependencies not found:');
    console.log('   Please install: npm install axios socket.io-client');
    return false;
  }
}

if (checkDependencies()) {
  testSocketConnection();
} else {
  process.exit(1);
}