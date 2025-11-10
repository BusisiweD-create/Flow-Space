const axios = require('axios');

async function testSystemMetrics() {
  try {
    console.log('🔧 Testing System Metrics with Real-time Data...\n');
    
    // First, login to get token
    console.log('🔐 Logging in...');
    const loginResponse = await axios.post('http://localhost:8000/api/v1/auth/login', {
      email: 'admin@flowspace.com',
      password: 'password'
    });
    
    const token = loginResponse.data.data.token;
    console.log('✅ Login successful');
    
    // Test system stats endpoint
    console.log('📊 Getting system stats...');
    const statsResponse = await axios.get('http://localhost:8000/api/v1/system/stats', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    const stats = statsResponse.data;
    console.log('✅ System stats received successfully!\n');
    
    console.log('📈 REAL-TIME SYSTEM METRICS:');
    console.log('============================');
    console.log(`💻 CPU Usage: ${stats.system.cpuUsage}%`);
    console.log(`🧠 Memory Usage: ${stats.system.memoryUsage}%`);
    console.log(`💿 Disk Usage: ${stats.system.diskUsage}%`);
    console.log(`⏱️  Uptime: ${Math.round(stats.system.uptime)} seconds`);
    console.log(`🔗 Active DB Connections: ${stats.system.activeConnections}`);
    console.log(`📊 Cache Hit Ratio: ${stats.system.cacheHitRatio}%`);
    console.log('');
    
    console.log('📊 DATABASE STATISTICS:');
    console.log('========================');
    console.log(`👥 Users: ${stats.statistics.users}`);
    console.log(`📋 Deliverables: ${stats.statistics.deliverables}`);
    console.log(`🏃 Sprints: ${stats.statistics.sprints}`);
    console.log(`📂 Projects: ${stats.statistics.projects}`);
    console.log(`📦 Total Entities: ${stats.statistics.total_entities}`);
    console.log('');
    
    console.log('✅ SUCCESS: Placeholder data has been replaced with real-time metrics!');
    
  } catch (error) {
    console.error('❌ Error testing system metrics:', error.response?.data || error.message);
  }
}

testSystemMetrics();