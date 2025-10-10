const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Test route
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Backend server is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Test authentication route
app.post('/api/v1/auth/register', (req, res) => {
  const { email, password, name, role } = req.body;
  
  console.log('📝 Registration attempt:', { email, name, role });
  
  // Simulate successful registration
  res.json({
    success: true,
    message: 'User registered successfully',
    data: {
      id: 'test-user-id',
      email,
      name,
      role,
      createdAt: new Date().toISOString()
    }
  });
});

// Test login route
app.post('/api/v1/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  console.log('🔐 Login attempt:', { email });
  
  // Simulate successful login
  res.json({
    success: true,
    message: 'Login successful',
    data: {
      user: {
        id: 'test-user-id',
        email,
        name: 'Test User',
        role: 'teamMember',
        createdAt: new Date().toISOString()
      },
      token: 'mock-jwt-token-' + Date.now()
    }
  });
});

// Test current user route
app.get('/api/v1/auth/me', (req, res) => {
  console.log('👤 Current user request');
  
  res.json({
    success: true,
    data: {
      id: 'test-user-id',
      email: 'test@example.com',
      name: 'Test User',
      role: 'teamMember',
      createdAt: new Date().toISOString()
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Test server running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth endpoints: http://localhost:${PORT}/api/v1/auth/*`);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down test server...');
  process.exit(0);
});
