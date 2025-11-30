const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');
const ProfessionalEmailService = require('./emailServiceProfessional');
const dbConfig = require('./database-config');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Initialize professional email service
const emailService = new ProfessionalEmailService();

// Middleware
app.use(cors());
app.use(express.json());

app.get('/api/v1', (req, res) => {
  res.send('Flow-Space API v1 is running');
});


// PostgreSQL connection using shared database config
const pool = new Pool(dbConfig);

// Test database connection with retry logic
let dbConnected = false;
const maxRetries = 5;
let retryCount = 0;

async function connectToDatabase() {
  try {
    const client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database');
    client.release();
    dbConnected = true;
  } catch (error) {
    retryCount++;
    console.log(`❌ Database connection attempt ${retryCount}/${maxRetries} failed:`, error.message);
    
    if (retryCount < maxRetries) {
      console.log(`🔄 Retrying in 2 seconds...`);
      setTimeout(connectToDatabase, 2000);
    } else {
      console.error('❌ Failed to connect to database after', maxRetries, 'attempts');
      process.exit(1);
    }
  }
}

// Start database connection
connectToDatabase();

// JWT middleware
const authenticateToken = (req, res, next) => {
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
};

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
    
    // Send welcome email
    try {
      await emailService.sendWelcomeEmail(email, name, role);
      console.log('✅ Welcome email sent successfully');
    } catch (emailError) {
      console.error('❌ Failed to send welcome email:', emailError);
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
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
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
      'SELECT id, email, password_hash, name, role, is_active, last_login_at FROM users WHERE email = $1',
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
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    
    // Update last login
    await pool.query(
      'UPDATE users SET last_login_at = $1 WHERE id = $2',
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
          name: user.name,
          role: user.role,
          lastLoginAt: user.last_login_at
        },
        token
      }
    });
    
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/v1/auth/me', authenticateToken, async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    const { userId } = req.user;
    
    const result = await pool.query(
      `SELECT u.id, u.email, u.name, u.role, u.avatar_url, u.created_at, u.last_login_at, u.is_active, u.preferences,
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
        avatarUrl: user.avatar_url,
        createdAt: user.created_at,
        lastLoginAt: user.last_login_at,
        isActive: user.is_active,
        preferences: user.preferences || {}
      }
    });
    
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/auth/logout', authenticateToken, (req, res) => {
  // In a real app, you might want to blacklist the token
  res.json({
    success: true,
    message: 'Logout successful'
  });
});

// User management routes (admin only)
app.get('/api/v1/users', authenticateToken, async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    // Check if user is admin
    const { role } = req.user;
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
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/v1/users/:userId/role', authenticateToken, async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    // Check if user is admin
    const { role } = req.user;
    if (role !== 'systemAdmin') {
      return res.status(403).json({ error: 'Admin access required' });
    }
    
    const { userId } = req.params;
    const { newRole } = req.body;
    
    if (!newRole) {
      return res.status(400).json({ error: 'New role is required' });
    }
    
    // Validate role exists
    const roleCheck = await pool.query('SELECT id FROM user_roles WHERE name = $1', [newRole]);
    if (roleCheck.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid role' });
    }
    
    // Update user role
    const result = await pool.query(
      'UPDATE users SET role = $1, updated_at = $2 WHERE id = $3 RETURNING id, email, name, role',
      [newRole, new Date().toISOString(), userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Log the role change
    await pool.query(
      `INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details)
       VALUES ($1, $2, $3, $4, $5)`,
      [req.user.userId, 'role_changed', 'user', userId, JSON.stringify({ newRole })]
    );
    
    res.json({
      success: true,
      message: 'User role updated successfully',
      data: result.rows[0]
    });
    
  } catch (error) {
    console.error('Update user role error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Deliverables routes
app.get('/api/v1/deliverables', authenticateToken, async (req, res) => {
  try {
    if (!dbConnected) {
      return res.status(503).json({ error: 'Database not connected. Please try again in a moment.' });
    }
    
    const { userId, role } = req.user;
    
    let query;
    let params;
    
    // Role-based filtering
    if (role === 'systemAdmin' || role === 'deliveryLead') {
      // Admins and delivery leads can see all deliverables
      query = `
        SELECT d.*, u.name as created_by_name, u2.name as assigned_to_name
        FROM deliverables d
        LEFT JOIN users u ON d.created_by = u.id
        LEFT JOIN users u2 ON d.assigned_to = u2.id
        ORDER BY d.created_at DESC
      `;
      params = [];
    } else {
      // Other roles can only see their own deliverables
      query = `
        SELECT d.*, u.name as created_by_name, u2.name as assigned_to_name
        FROM deliverables d
        LEFT JOIN users u ON d.created_by = u.id
        LEFT JOIN users u2 ON d.assigned_to = u2.id
        WHERE d.created_by = $1 OR d.assigned_to = $1
        ORDER BY d.created_at DESC
      `;
      params = [userId];
    }
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows
    });
    
  } catch (error) {
    console.error('Get deliverables error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Flow-Space Backend Server running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth endpoints: http://localhost:${PORT}/api/v1/auth/*`);
  console.log(`👥 User management: http://localhost:${PORT}/api/v1/users/*`);
  console.log(`📦 Deliverables: http://localhost:${PORT}/api/v1/deliverables`);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  pool.end();
  process.exit(0);
});
