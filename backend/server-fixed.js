// Load environment variables first
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');
const dbConfig = require('./database-config');
const EmailService = require('./emailService');
const ErrorHandler = require('./utils/errorHandler');

const app = express();
const PORT = process.env.PORT || 8000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Initialize email service
const emailService = new EmailService();

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection
const pool = new Pool({
  ...dbConfig,
  database: 'flow_space'
});

// Test database connection
let dbConnected = false;

async function testDatabaseConnection() {
  try {
    const client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database');
    client.release();
    dbConnected = true;
    return true;
  } catch (error) {
    ErrorHandler.logError(error, 'Database connection failed');
    dbConnected = false;
    return false;
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Flow-Space Backend Server',
    database: dbConnected ? 'Connected' : 'Disconnected',
    timestamp: new Date().toISOString(),
    version: '2.0.0'
  });
});

// Auth routes
app.post('/api/v1/auth/register', async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    const { email, password, name, role } = req.body;
    
    // Validate input
    if (!email || !password || !name || !role) {
      return res.status(400).json({ error: 'Email, password, name, and role are required' });
    }
    
    // Check if user already exists
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: 'User with this email already exists' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    
    // Insert user into users table
    const result = await pool.query(
      `INSERT INTO users (id, email, password_hash, name, role, created_at)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, email, name, role, created_at, is_active`,
      [userId, email, hashedPassword, name, role, new Date().toISOString()]
    );
    
    const user = result.rows[0];
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Send verification email
    console.log(`📧 Sending verification email to: ${user.email}`);
    
    // Generate a 6-digit verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    try {
      const emailResult = await emailService.sendVerificationEmail(
        user.email, 
        user.name, 
        verificationCode
      );
      
      if (emailResult.success) {
        console.log('✅ Verification email sent successfully:', emailResult.messageId);
      } else {
        console.log('❌ Failed to send verification email:', emailResult.error);
      }
    } catch (emailError) {
      ErrorHandler.logError(emailError, 'Email sending failed during registration');
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          isActive: user.is_active,
          createdAt: user.created_at
        },
        token
      }
    });
    
  } catch (error) {
    const errorResponse = ErrorHandler.handleDatabaseError(error, 'user registration');
    res.status(500).json(errorResponse);
  }
});

app.post('/api/v1/auth/login', async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    // Find user by email
    const result = await pool.query(
      'SELECT id, email, hashed_password, first_name, last_name, role, is_active, last_login, created_at FROM users WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    
    const user = result.rows[0];
    
    // Check if user is active
    if (!user.is_active) {
      return res.status(401).json({ error: 'Account is deactivated' });
    }
    
    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.hashed_password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    
    // Update last login
    await pool.query(
      'UPDATE users SET last_login = $1 WHERE id = $2',
      [new Date().toISOString(), user.id]
    );
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: `${user.first_name} ${user.last_name}`,
          role: user.role,
          createdAt: user.created_at,
          lastLoginAt: user.last_login,
          isActive: user.is_active ?? true,
          projectIds: [],
          preferences: {},
          emailVerified: true, // Assume verified since they can login
          emailVerifiedAt: user.created_at // Use created_at as verification time
        },
        token
      }
    });
    
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/v1/auth/me', async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: 'Access token required' });
    }

    // Verify JWT token
    const decoded = jwt.verify(token, JWT_SECRET);
    const { userId } = decoded;
    
    const result = await pool.query(
      `SELECT u.id, u.email, u.name, u.role, u.created_at, u.last_login_at, u.is_active,
              ur.display_name, ur.description, ur.color, ur.icon
       FROM users u
       JOIN user_roles ur ON u.role = ur.name
       WHERE u.id = $1`,
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = result.rows[0];
    
    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        roleDisplayName: user.display_name,
        roleDescription: user.description,
        roleColor: user.color,
        roleIcon: user.icon,
        createdAt: user.created_at,
        lastLoginAt: user.last_login_at,
        isActive: user.is_active
      }
    });
    
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    console.error('Get current user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/auth/logout', (req, res) => {
  res.json({
    success: true,
    message: 'Logout successful'
  });
});

// Email verification endpoint
app.post('/api/v1/auth/verify-email', async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    const { email, verificationCode, verification_code } = req.body;
    
    // Accept both verificationCode and verification_code for compatibility
    const code = verificationCode || verification_code;
    
    if (!email || !code) {
      return res.status(400).json({ error: 'Email and verification code are required' });
    }
    
    // For now, we'll accept any 6-digit code as valid
    // In a real implementation, you'd store and verify the code from the database
    if (code.length === 6 && /^\d+$/.test(code)) {
      console.log(`✅ Email verification successful for: ${email}`);
      
      res.json({
        success: true,
        message: 'Email verified successfully',
        data: {
          email: email,
          verified: true
        }
      });
    } else {
      res.status(400).json({ 
        success: false,
        error: 'Invalid verification code. Please enter the 6-digit code sent to your email.' 
      });
    }
    
  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// User management routes (admin only)
app.get('/api/v1/users', async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: 'Access token required' });
    }

    // Verify JWT token
    const decoded = jwt.verify(token, JWT_SECRET);
    const { role } = decoded;
    
    // Check if user is admin
    if (role !== 'systemAdmin') {
      return res.status(403).json({ error: 'Admin access required' });
    }
    
    const result = await pool.query(
      `SELECT u.id, u.email, u.name, u.role, u.is_active, u.created_at, u.last_login_at,
              ur.display_name, ur.color, ur.icon
       FROM users u
       JOIN user_roles ur ON u.role = ur.name
       ORDER BY u.created_at DESC`
    );
    
    res.json({
      success: true,
      data: result.rows
    });
    
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Test endpoint
app.get('/api/v1/test', async (req, res) => {
  try {
    const result = await pool.query('SELECT COUNT(*) as user_count FROM users');
    res.json({
      success: true,
      message: 'Database connection working',
      data: {
        userCount: result.rows[0].user_count,
        databaseConnected: dbConnected
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Start server
async function startServer() {
  console.log('🚀 Starting Flow-Space Backend Server...\n');
  
  // Test database connection
  const dbTest = await testDatabaseConnection();
  
  if (!dbTest) {
    console.log('⚠️  Starting server without database connection');
  }
  
  app.listen(PORT, () => {
    console.log(`🚀 Flow-Space Backend Server running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`🔐 Auth endpoints: http://localhost:${PORT}/api/v1/auth/*`);
    console.log(`👥 User management: http://localhost:${PORT}/api/v1/users`);
    console.log(`🧪 Test endpoint: http://localhost:${PORT}/api/v1/test`);
    console.log('\n✅ Server started successfully!');
  });
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  pool.end();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Shutting down server...');
  pool.end();
  process.exit(0);
});

// Start the server
startServer().catch(console.error);
