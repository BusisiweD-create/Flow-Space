
import http from 'http';

function testEndpoint(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: 8000,
      path: path,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      console.log(`GET ${path} -> Status: ${res.statusCode}`);
      resolve(res.statusCode);
    });

    req.on('error', (e) => {
      console.error(`GET ${path} -> Error: ${e.message}`);
      resolve(null);
    });

    req.end();
  });
}

async function runTests() {
  console.log('Testing endpoints on 127.0.0.1:8000...');
  
  // Test Health
  await testEndpoint('/api/v1/health');
  
  // Test Approval Requests
  await testEndpoint('/api/v1/approval-requests');
}

runTests();
