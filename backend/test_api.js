const http = require('http');

// Test deliverables endpoint
const testDeliverables = () => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 8000,
      path: '/api/v1/deliverables',
      method: 'GET',
      headers: {
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Ijc1NTRkNWQwLThkYWQtNDU5OS1hZjBhLWUwNDc2Y2JjNjUyYiIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInJvbGUiOiJ0ZWFtTWVtYmVyIiwiaWF0IjoxNzMxNDY3NDY5LCJleHAiOjE3MzE1NTM4Njl9.test'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        console.log('Deliverables endpoint - Status:', res.statusCode);
        console.log('Response:', data);
        resolve(data);
      });
    });

    req.on('error', (error) => {
      console.error('Deliverables endpoint error:', error.message);
      reject(error);
    });

    req.end();
  });
};

// Test sprints endpoint
const testSprints = () => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 8000,
      path: '/api/v1/sprints',
      method: 'GET',
      headers: {
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Ijc1NTRkNWQwLThkYWQtNDU5OS1hZjBhLWUwNDc2Y2JjNjUyYiIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInJvbGUiOiJ0ZWFtTWVtYmVyIiwiaWF0IjoxNzMxNDY3NDY5LCJleHAiOjE3MzE1NTM4Njl9.test'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        console.log('Sprints endpoint - Status:', res.statusCode);
        console.log('Response:', data);
        resolve(data);
      });
    });

    req.on('error', (error) => {
      console.error('Sprints endpoint error:', error.message);
      reject(error);
    });

    req.end();
  });
};

// Run tests
async function runTests() {
  try {
    console.log('Testing API endpoints...');
    await testDeliverables();
    console.log('---');
    await testSprints();
    console.log('---');
    console.log('Tests completed');
  } catch (error) {
    console.error('Test failed:', error);
  }
}

runTests();