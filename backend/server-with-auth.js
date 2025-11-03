const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Flow-Space Backend is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Authentication endpoints
app.post('/api/v1/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // For now, return a mock successful login
    const mockUser = {
      id: '80ebe775-1837-4ff5-a0a5-faabd46e0b96',
      email: email,
      name: 'Test User',
      role: 'deliveryLead',
      createdAt: new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
      isActive: true,
      projectIds: [],
      preferences: {},
      emailVerified: true,
      emailVerifiedAt: new Date().toISOString()
    };

    const token = jwt.sign(
      { userId: mockUser.id, email: mockUser.email, role: mockUser.role },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      data: {
        user: mockUser,
        token: token,
        refreshToken: token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

app.get('/api/v1/auth/me', authenticateToken, (req, res) => {
  try {
    const mockUser = {
      id: req.user.userId,
      email: req.user.email,
      name: 'Test User',
      role: req.user.role,
      createdAt: new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
      isActive: true,
      projectIds: [],
      preferences: {},
      emailVerified: true,
      emailVerifiedAt: new Date().toISOString()
    };

    res.json({
      success: true,
      data: mockUser
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

// JWT Authentication middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}

// Test endpoint
app.get('/api/v1/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'API is working',
    data: { test: 'success' }
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`🚀 Flow-Space Backend Server running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth endpoints: http://localhost:${PORT}/api/v1/auth/*`);
});
