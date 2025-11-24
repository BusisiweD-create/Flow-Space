// Load environment variables
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// OpenAI for AI-powered readiness analysis
let OpenAI = null;
let openai = null;
try {
  OpenAI = require('openai');
  if (process.env.OPENAI_API_KEY) {
    openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    console.log('✅ OpenAI initialized (GPT-3.5-turbo)');
  } else {
    console.log('⚠️  OPENAI_API_KEY not set - AI features will use fallback analysis');
  }
} catch (error) {
  console.log('⚠️  OpenAI package not installed - AI features will use fallback analysis');
}

const app = express();
const PORT = process.env.PORT || 3001;

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

// Email Configuration
let emailTransporter = null;

if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
  emailTransporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
  
  // Test email configuration
  emailTransporter.verify((error, success) => {
    if (error) {
      console.log('⚠️  Email configuration error:', error.message);
      console.log('💡 Email functionality will be disabled until credentials are configured');
    } else {
      console.log('✅ Email server is ready to send messages');
    }
  });
} else {
  console.log('⚠️  Email credentials not configured - email functionality disabled');
  console.log('💡 Set EMAIL_USER and EMAIL_PASS in .env file to enable email features');
}

// Middleware - Configure CORS for Flutter Web
app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);
    
    // Allow localhost on any port (for development)
    if (origin.match(/^http:\/\/localhost:\d+$/) || 
        origin.match(/^http:\/\/127\.0\.0\.1:\d+$/)) {
      return callback(null, true);
    }
    
    // Allow specific origins
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:3001', 
      'http://localhost:8080',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:3001',
      'http://127.0.0.1:8080'
    ];
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.log('⚠️  CORS: Allowing origin:', origin);
      callback(null, true); // Allow all in development
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(express.json());

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  },
  fileFilter: function (req, file, cb) {
    // Allow all file types for now
    cb(null, true);
  }
});

// Authentication middleware
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

// PostgreSQL connection
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'flow_space',
  password: 'postgres',
  port: 5432,
});

// Test database connection
pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

// Auth routes
// Register endpoint (matching frontend expectations)
app.post('/api/v1/auth/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, company, role } = req.body;
    
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({ 
        success: false,
        error: 'Email, password, first name, and last name are required' 
      });
    }
    
    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ 
        success: false,
        error: 'User with this email already exists' 
      });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const fullName = `${firstName} ${lastName}`;
    
    // Insert user into users table
    const result = await pool.query(
      `INSERT INTO users (id, email, password_hash, name, role, is_active, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, email, name, role, created_at`,
      [userId, email, hashedPassword, fullName, role || 'user', true, new Date().toISOString(), new Date().toISOString()]
    );
    
    const user = result.rows[0];
    
    // Create JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    
    // Generate and display verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    console.log('\n🎉 ===========================================');
    console.log(`📧 VERIFICATION CODE FOR: ${email}`);
    console.log(`🔢 CODE: ${verificationCode}`);
    console.log('===========================================\n');
    
    // Try to send verification email
    try {
      if (emailTransporter) {
        const mailOptions = {
          from: process.env.EMAIL_USER,
          to: email,
          subject: 'Flow-Space Email Verification',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #333;">Welcome to Flow-Space!</h2>
              <p>Thank you for registering with Flow-Space. Please use the following verification code to complete your registration:</p>
              <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
                <h1 style="color: #007bff; font-size: 32px; margin: 0;">${verificationCode}</h1>
              </div>
              <p>This code will expire in 10 minutes.</p>
              <p>If you didn't request this verification, please ignore this email.</p>
              <hr style="margin: 30px 0;">
              <p style="color: #666; font-size: 14px;">Best regards,<br>The Flow-Space Team</p>
            </div>
          `
        };

        await emailTransporter.sendMail(mailOptions);
        console.log(`📧 Verification email sent to: ${email}`);
      } else {
        console.log('⚠️  Email service not configured - verification email not sent');
        console.log('💡 User can still login using the verification code shown above');
      }
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError.message);
      console.log('💡 Check the console above for the verification code');
    }
    
    console.log(`✅ User registered: ${user.email}`);
    
    res.status(201).json({
      success: true,
      message: 'Registration successful. Please check your email for verification code.',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          createdAt: user.created_at,
          isActive: user.is_active
        },
        token: token,
        token_type: 'Bearer'
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

app.post('/api/v1/auth/signup', async (req, res) => {
  try {
    const { email, password, firstName, lastName, company, role } = req.body;
    
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({ 
        success: false,
        error: 'Email, password, first name, and last name are required' 
      });
    }
    
    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ 
        success: false,
        error: 'User with this email already exists' 
      });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const fullName = `${firstName} ${lastName}`;
    
    // Insert user into users table
    const result = await pool.query(
      `INSERT INTO users (id, email, password_hash, name, role, is_active, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, email, name, role, created_at`,
      [userId, email, hashedPassword, fullName, role || 'user', true, new Date().toISOString(), new Date().toISOString()]
    );
    
    const user = result.rows[0];
    
    // Create JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    
    console.log(`✅ User registered: ${user.email}`);
    
    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          createdAt: user.created_at,
          isActive: user.is_active
        },
        token: token,
        token_type: 'Bearer'
      }
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Login endpoint (matching frontend expectations)
app.post('/api/v1/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    console.log(`🔐 Login attempt for email: ${email}`);
    
    if (!email || !password) {
      return res.status(400).json({ 
        success: false,
        error: 'Email and password are required' 
      });
    }
    
    // Find user by email in users table
    const result = await pool.query(
      'SELECT id, email, password_hash, name, role, created_at, is_active FROM users WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      console.log(`❌ User not found: ${email}`);
      return res.status(401).json({ 
        success: false,
        error: 'Invalid credentials' 
      });
    }
    
    const user = result.rows[0];
    
    // Check if user is active
    if (!user.is_active) {
      console.log(`❌ Account deactivated: ${email}`);
      return res.status(401).json({ 
        success: false,
        error: 'Account is deactivated' 
      });
    }
    
    // Check if password_hash exists
    if (!user.password_hash) {
      console.log(`❌ No password hash for user: ${email}`);
      return res.status(401).json({ 
        success: false,
        error: 'Invalid credentials' 
      });
    }
    
    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      console.log(`❌ Invalid password for user: ${email}`);
      return res.status(401).json({ 
        success: false,
        error: 'Invalid credentials' 
      });
    }
    
    // Create JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    
    console.log(`✅ User logged in: ${user.email}`);
    
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          createdAt: user.created_at,
          isActive: user.is_active
        },
        token: token,
        token_type: 'Bearer'
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Logout endpoint
app.post('/api/v1/auth/logout', authenticateToken, async (req, res) => {
  try {
    // Since we're using stateless JWT, logout is mainly client-side
    // But we can log the logout event or invalidate tokens if needed
    console.log(`✅ User logged out: ${req.user.email}`);
    
    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Keep the old signin endpoint for backward compatibility
app.post('/api/v1/auth/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    // Find user by email in users table
    const result = await pool.query(
      'SELECT id, email, password_hash, name, role, created_at FROM users WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = result.rows[0];
    
    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Create JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    
    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        createdAt: user.created_at
      },
      access_token: token,
      token_type: 'Bearer'
    });
  } catch (error) {
    console.error('Signin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get current user info
app.get('/api/v1/auth/me', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get user details from database
    const result = await pool.query(
      'SELECT id, email, name, role, created_at FROM users WHERE id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }
    
    const user = result.rows[0];
    
    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          createdAt: user.created_at
        }
      }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});
// Deliverables routes - REMOVED: This endpoint is duplicated below with authentication
// The authenticated version at line 1262 should be used instead
// User settings endpoint
app.get('/api/user/settings', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get user settings/preferences from database
    const result = await pool.query(
      'SELECT id, email, name, role, is_active, created_at FROM users WHERE id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }
    
    const user = result.rows[0];
    
    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        isActive: user.is_active,
        createdAt: user.created_at,
        // Default settings
        theme: 'light',
        notifications: true,
        language: 'en'
      }
    });
  } catch (error) {
    console.error('Get user settings error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Deliverables routes
// OLD ENDPOINT REMOVED - Using authenticated version below (line 1804)
// This old version tried to use 'profiles' table which doesn't exist

// REMOVED: Unauthenticated POST /api/v1/deliverables endpoint
// This endpoint is duplicated below with authentication at line 1274
// The authenticated version should be used instead

app.put('/api/v1/deliverables/:id', async (req, res) => {
  try {
    const { id } = req.params;
    let { status } = req.body;
    
    await pool.query(
      'UPDATE deliverables SET status = $1, updated_at = $2 WHERE id = $3::uuid',
      [status, new Date().toISOString(), id]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Update deliverable error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Sprints routes
app.get('/api/v1/sprints', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.id, s.name, s.description, s.status, s.project_id, s.created_by, s.created_at, s.updated_at,
             u.name as created_by_name
      FROM sprints s
      LEFT JOIN users u ON s.created_by::uuid = u.id::uuid
      ORDER BY s.created_at DESC
    `);
    
    const sprints = result.rows.map(row => ({
      id: row.id,
      name: row.name || 'Unnamed Sprint',
      description: row.description || '',
      status: row.status || 'planning',
      project_id: row.project_id,
      created_by: row.created_by,
      created_at: row.created_at,
      updated_at: row.updated_at,
      created_by_name: row.created_by_name || 'Unknown',
    }));
    
    res.json({
      success: true,
      data: sprints
    });
  } catch (error) {
    console.error('Get sprints error:', error);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    
    // If table doesn't exist or column error, return empty array
    if (error.code === '42P01' || error.code === '42703') {
      console.log('Sprints table or column does not exist, returning empty array');
      return res.json({
        success: true,
        data: []
      });
    }
    
    // Return empty array for any error instead of 500
    res.json({
      success: true,
      data: []
    });
  }
});

app.post('/api/v1/sprints', authenticateToken, async (req, res) => {
  try {
    const { name, description, start_date, end_date, project_id, plannedPoints } = req.body;
    const userId = req.user.id;
    
    if (!name || !start_date || !end_date) {
      return res.status(400).json({
        success: false,
        error: 'Name, start_date, and end_date are required'
      });
    }
    
    const result = await pool.query(
      `INSERT INTO sprints (name, description, start_date, end_date, project_id, created_by, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        name, 
        description || '', 
        start_date, 
        end_date,
        project_id || null,
        userId, 
        new Date().toISOString(), 
        new Date().toISOString()
      ]
    );
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Create sprint error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to create sprint',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Sprint board endpoints
app.get('/api/v1/sprints/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT s.*, u.name as created_by_name
      FROM sprints s
      LEFT JOIN users u ON s.created_by::uuid = u.id::uuid
      WHERE s.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Sprint not found' 
      });
    }
    
    const sprint = result.rows[0];
    res.json({
      success: true,
      data: {
        id: sprint.id,
        name: sprint.name,
        description: sprint.description,
        status: sprint.status,
        project_id: sprint.project_id,
        start_date: sprint.start_date,
        end_date: sprint.end_date,
        created_by: sprint.created_by,
        created_at: sprint.created_at,
        updated_at: sprint.updated_at,
        created_by_name: sprint.created_by_name
      }
    });
  } catch (error) {
    console.error('Get sprint error:', error);
    if (error.message === 'Sprint not found') {
      return res.status(404).json({ 
        success: false,
        error: 'Sprint not found' 
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

app.get('/api/v1/sprints/:id/tickets', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT t.*, s.name as sprint_name
      FROM tickets t
      LEFT JOIN sprints s ON t.sprint_id::text = s.id::text
      WHERE t.sprint_id::text = $1
      ORDER BY t.created_at DESC
    `, [id]);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Get sprint tickets error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update sprint
app.put('/api/v1/sprints/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, name, description, start_date, end_date } = req.body;
    
    // Build dynamic update query
    const updates = [];
    const values = [];
    let paramCounter = 1;
    
    if (status !== undefined) {
      updates.push(`status = $${paramCounter}`);
      values.push(status);
      paramCounter++;
    }
    if (name !== undefined) {
      updates.push(`name = $${paramCounter}`);
      values.push(name);
      paramCounter++;
    }
    if (description !== undefined) {
      updates.push(`description = $${paramCounter}`);
      values.push(description);
      paramCounter++;
    }
    if (start_date !== undefined) {
      updates.push(`start_date = $${paramCounter}`);
      values.push(start_date);
      paramCounter++;
    }
    if (end_date !== undefined) {
      updates.push(`end_date = $${paramCounter}`);
      values.push(end_date);
      paramCounter++;
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ 
        success: false,
        error: 'No fields to update' 
      });
    }
    
    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);
    
    const result = await pool.query(`
      UPDATE sprints 
      SET ${updates.join(', ')}
      WHERE id = $${paramCounter}
      RETURNING *
    `, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Sprint not found' 
      });
    }
    
    console.log(`✅ Sprint ${id} updated successfully`);
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Update sprint error:', error);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    console.error('Error message:', error.message);
    
    // If table doesn't exist, return 404
    if (error.code === '42P01') {
      return res.status(404).json({ 
        success: false,
        error: 'Sprint not found' 
      });
    }
    
    // If column doesn't exist, return 400
    if (error.code === '42703') {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid field to update' 
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: error.message || 'Internal server error' 
    });
  }
});

app.post('/api/v1/sprints/:id/tickets', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, assignee, priority, type } = req.body;
    
    const result = await pool.query(`
      INSERT INTO tickets (ticket_id, ticket_key, summary, description, status, issue_type, priority, assignee, reporter, sprint_id, project_id, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `, [
      `TICK-${Date.now()}`,
      `FLOW-${Date.now()}`,
      title,
      description,
      'To Do',
      type || 'Task',
      priority || 'Medium',
      assignee,
      'system',
      id,
      null, // project_id
      new Date().toISOString()
    ]);
    
    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Create ticket error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Fallback: create ticket without sprint path (expects sprint_id in body)
app.post('/api/v1/tickets', authenticateToken, async (req, res) => {
  try {
    const {
      sprint_id: sprintIdSnake,
      sprintId: sprintIdCamel,
      title,
      description,
      assignee,
      priority,
      type
    } = req.body;
    const sprint_id = sprintIdSnake || sprintIdCamel;
    if (!req.user || !req.user.id) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    if (!sprint_id || !title) {
      return res.status(400).json({ success: false, error: 'sprint_id and title are required' });
    }
    const result = await pool.query(`
      INSERT INTO tickets (ticket_id, ticket_key, summary, description, status, issue_type, priority, assignee, reporter, sprint_id, project_id, created_at, user_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::uuid, $11, $12, $13)
      RETURNING *
    `, [
      `TICK-${Date.now()}`,
      `FLOW-${Date.now()}`,
      title,
      description || '',
      'To Do',
      type || 'Task',
      priority || 'Medium',
      assignee,
      'system',
      sprint_id,
      null,
      new Date().toISOString(),
      req.user.id
    ]);
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Create ticket (fallback) error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/v1/tickets/:id/status', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const result = await pool.query(`
      UPDATE tickets 
      SET status = $1, updated_at = $2
      WHERE ticket_id = $3
      RETURNING *
    `, [status, new Date().toISOString(), id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket not found' });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Update ticket status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Projects routes
app.get('/api/v1/projects', authenticateToken, async (req, res) => {
  try {
    console.log('📂 Fetching projects from database...');
    
    const result = await pool.query(`
      SELECT p.id, p.name, p.key, p.description, p.project_type, p.status, 
             p.start_date, p.end_date,
             p.owner_id, p.created_at, p.updated_at,
             u.name as created_by_name
      FROM projects p
      LEFT JOIN users u ON p.owner_id::uuid = u.id::uuid
      ORDER BY p.created_at DESC
    `);
    
    console.log(`✅ Found ${result.rows.length} projects in database`);
    if (result.rows.length > 0) {
      console.log('Project names:', result.rows.map(p => p.name).join(', '));
    }
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ Get projects error:', error);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    console.error('Error message:', error.message);
    
    // If table doesn't exist or column error, return empty array
    if (error.code === '42P01') {
      console.log('⚠️ Projects table does not exist, returning empty array');
      return res.json({
        success: true,
        data: []
      });
    }
    
    if (error.code === '42703') {
      console.log('⚠️ Column does not exist in projects table, returning empty array');
      console.log('Available columns might not match query. Error:', error.message);
      return res.json({
        success: true,
        data: []
      });
    }
    
    // For other errors, log and return empty array
    console.log('⚠️ Returning empty array due to unexpected error');
    res.json({
      success: true,
      data: []
    });
  }
});

app.post('/api/v1/projects', authenticateToken, async (req, res) => {
  try {
    const { name, key, description, projectType, start_date, end_date } = req.body;
    const userId = req.user.id;
    
    console.log('📝 Creating project:', { name, key, userId });
    
    if (!name) {
      console.log('❌ Project name is required');
      return res.status(400).json({ 
        success: false,
        error: 'Name is required' 
      });
    }
    
    // Insert with all available columns
    const result = await pool.query(`
      INSERT INTO projects (name, key, description, project_type, status, owner_id, start_date, end_date)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `, [
      name, 
      key || null,
      description || '', 
      projectType || 'agile',
      'active',
      userId,
      start_date || null,
      end_date || null
    ]);
    
    console.log('✅ Project created successfully:', result.rows[0].id);
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Create project error:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Error detail:', error.detail);
    
    res.status(500).json({ 
      success: false,
      error: error.message || 'Internal server error' 
    });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Flow-Space API is running' });
});

// Audit logs endpoint
app.get('/api/audit-logs', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const offset = parseInt(skip);
    const parsedLimit = parseInt(limit);
    
    // Get audit logs with pagination
    const auditLogsResult = await pool.query(
      `SELECT al.*, u.name as user_name, u.email as user_email
       FROM audit_logs al
       LEFT JOIN users u ON al.user_id = u.id
       ORDER BY al.created_at DESC
       LIMIT $1 OFFSET $2`,
      [parsedLimit, offset]
    );
    
    // Get total count for pagination
    const totalCountResult = await pool.query('SELECT COUNT(*) as total FROM audit_logs');
    const totalCount = parseInt(totalCountResult.rows[0].total);
    
    const auditLogs = auditLogsResult.rows.map(log => ({
      id: log.id,
      user_id: log.user_id,
      user_name: log.user_name,
      user_email: log.user_email,
      action: log.action,
      resource_type: log.resource_type,
      resource_id: log.resource_id,
      details: log.details,
      ip_address: log.ip_address,
      user_agent: log.user_agent,
      created_at: log.created_at
    }));
    
    res.json({
      audit_logs: auditLogs,
      items: auditLogs, // For backward compatibility
      logs: auditLogs,  // For backward compatibility
      total: totalCount,
      total_count: totalCount,
      skip: offset,
      limit: parsedLimit,
      has_more: offset + auditLogs.length < totalCount
    });
  } catch (error) {
    if (error.code === '42P01') { // Table doesn't exist
       console.log('Audit logs table does not exist yet, returning empty response');
       res.json({
         audit_logs: [],
         items: [],
         logs: [],
         total: 0,
         total_count: 0,
         skip: 0,
         limit: 100,
         has_more: false
       });
    } else {
      console.error('Error fetching audit logs:', error);
      res.status(500).json({ 
        success: false,
        error: 'Internal server error' 
      });
    }
  }
});

// Audit logs endpoint (v1)
app.get('/api/v1/audit-logs', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const offset = parseInt(skip);
    const parsedLimit = parseInt(limit);
    
    // Get audit logs with pagination
    const auditLogsResult = await pool.query(
      `SELECT al.*, u.name as user_name, u.email as user_email
       FROM audit_logs al
       LEFT JOIN users u ON al.user_id = u.id
       ORDER BY al.created_at DESC
       LIMIT $1 OFFSET $2`,
      [parsedLimit, offset]
    );
    
    // Get total count for pagination
    const totalCountResult = await pool.query('SELECT COUNT(*) as total FROM audit_logs');
    const totalCount = parseInt(totalCountResult.rows[0].total);
    
    const auditLogs = auditLogsResult.rows.map(log => ({
      id: log.id,
      user_id: log.user_id,
      user_name: log.user_name,
      user_email: log.user_email,
      action: log.action,
      resource_type: log.resource_type,
      resource_id: log.resource_id,
      details: log.details,
      ip_address: log.ip_address,
      user_agent: log.user_agent,
      created_at: log.created_at
    }));
    
    res.json({
      audit_logs: auditLogs,
      items: auditLogs,
      logs: auditLogs,
      total: totalCount,
      total_count: totalCount,
      skip: offset,
      limit: parsedLimit,
      has_more: offset + auditLogs.length < totalCount
    });
  } catch (error) {
    if (error.code === '42P01') { // Table doesn't exist
       console.log('Audit logs table does not exist yet, returning empty response');
       res.json({
         audit_logs: [],
         items: [],
         logs: [],
         total: 0,
         total_count: 0,
         skip: 0,
         limit: 100,
         has_more: false
       });
    } else {
      console.error('Error fetching audit logs:', error);
      res.status(500).json({ 
        success: false,
        error: 'Internal server error' 
      });
    }
  }
});

// Test database connection
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time');
    res.json({ 
      status: 'OK', 
      message: 'Database connection successful',
      current_time: result.rows[0].current_time
    });
  } catch (error) {
    console.error('Database test error:', error);
    res.status(500).json({ 
      status: 'ERROR', 
      message: 'Database connection failed',
      error: error.message
    });
  }
});

// User management endpoints
app.get('/api/v1/users', authenticateToken, async (req, res) => {
  try {
    // Check if user is admin
    const { role } = req.user;
    if (role !== 'systemAdmin') {
      return res.status(403).json({ 
        success: false,
        error: 'Admin access required' 
      });
    }
    
    const result = await pool.query(
      `SELECT u.id, u.email, u.name, u.role, u.is_active, u.created_at, u.last_login_at,
              ur.display_name, ur.color, ur.icon
       FROM users u
       LEFT JOIN user_roles ur ON u.role = ur.name
       ORDER BY u.created_at DESC`
    );
    
    res.json({
      success: true,
      data: result.rows
    });
    
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

app.put('/api/v1/users/:userId/role', authenticateToken, async (req, res) => {
  try {
    // Check if user is admin
    const { role } = req.user;
    if (role !== 'systemAdmin') {
      return res.status(403).json({ 
        success: false,
        error: 'Admin access required' 
      });
    }
    
    const { userId } = req.params;
    const { role: newRole } = req.body;
    
    if (!newRole) {
      return res.status(400).json({ 
        success: false,
        error: 'Role is required' 
      });
    }
    
    // Validate role
    const validRoles = ['teamMember', 'deliveryLead', 'clientReviewer', 'systemAdmin'];
    if (!validRoles.includes(newRole)) {
      return res.status(400).json({ 
        success: false,
        error: `Invalid role. Must be one of: ${validRoles.join(', ')}` 
      });
    }
    
    const result = await pool.query(
      'UPDATE users SET role = $1, updated_at = $2 WHERE id = $3 RETURNING *',
      [newRole, new Date().toISOString(), userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
    
  } catch (error) {
    console.error('Update user role error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

app.put('/api/v1/users/:userId/status', authenticateToken, async (req, res) => {
  try {
    // Check if user is admin
    const { role } = req.user;
    if (role !== 'systemAdmin') {
      return res.status(403).json({ 
        success: false,
        error: 'Admin access required' 
      });
    }
    
    const { userId } = req.params;
    const { isActive } = req.body;
    
    if (typeof isActive !== 'boolean') {
      return res.status(400).json({ 
        success: false,
        error: 'isActive must be a boolean' 
      });
    }
    
    const result = await pool.query(
      'UPDATE users SET is_active = $1, updated_at = $2 WHERE id = $3 RETURNING *',
      [isActive, new Date().toISOString(), userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
    
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Tickets routes
app.get('/api/v1/sprints/:sprintId/tickets', async (req, res) => {
  try {
    const { sprintId } = req.params;
    
    const result = await pool.query(`
      SELECT t.*, u.first_name, u.last_name
      FROM tickets t
      LEFT JOIN users u ON t.assignee = u.email
      WHERE t.sprint_id::text = $1
      ORDER BY t.created_at DESC
    `, [sprintId]);
    
    const tickets = result.rows.map(row => ({
      id: row.ticket_id, // Use ticket_id instead of id
      title: row.summary,
      description: row.description,
      status: row.status,
      assigned_to: row.assignee,
      created_by: row.reporter,
      sprint_id: row.sprint_id,
      priority: row.priority,
      due_date: null, // Not in current schema
      created_at: row.created_at,
      updated_at: row.updated_at,
      assigned_user_name: row.first_name ? `${row.first_name} ${row.last_name}` : null,
    }));
    
    res.json({
      success: true,
      data: tickets
    });
  } catch (error) {
    console.error('Get sprint tickets error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Removed duplicate unauthenticated POST /api/v1/tickets route

// Update ticket status endpoint
app.put('/api/v1/tickets/:ticketId/status', async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { status } = req.body;
    
    if (!status) {
      return res.status(400).json({ 
        success: false,
        error: 'Status is required' 
      });
    }
    
    const result = await pool.query(`
      UPDATE tickets 
      SET status = $1, updated_at = $2
      WHERE ticket_id = $3
      RETURNING *
    `, [status, new Date().toISOString(), ticketId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Ticket not found' 
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Update ticket status error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Update sprint status
app.put('/api/v1/sprints/:sprintId/status', authenticateToken, async (req, res) => {
  try {
    const { sprintId } = req.params;
    let { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Status is required'
      });
    }

    // Normalize and validate status values
    let normalizedStatus = status;
    if (status === 'planned') {
      normalizedStatus = 'planning';
    }
    const validStatuses = ['planning', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(normalizedStatus)) {
      return res.status(400).json({
        success: false,
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
      });
    }

    const result = await pool.query(`
      UPDATE sprints
      SET status = $1::text, updated_at = NOW()
      WHERE id = $2::uuid
      RETURNING *
    `, [normalizedStatus, sprintId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Sprint not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Update sprint status error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: error.message || 'Internal server error'
    });
  }
});

// ==================== NOTIFICATION ENDPOINTS ====================

// Get all notifications for the current user
app.get('/api/v1/notifications', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const result = await pool.query(`
      SELECT 
        n.id,
        n.title,
        n.message,
        n.type,
        n.is_read,
        n.created_at,
        n.updated_at,
        u.name as created_by_name
      FROM notifications n
      LEFT JOIN users u ON n.created_by = u.id
      WHERE n.user_id = $1 OR n.user_id IS NULL
      ORDER BY n.created_at DESC
    `, [userId]);

    res.json({
      success: true,
      data: result.rows.map(row => ({
        id: row.id,
        title: row.title,
        message: row.message,
        type: row.type,
        isRead: row.is_read,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        createdByName: row.created_by_name,
        timestamp: row.created_at,
        date: row.created_at,
        description: row.message
      }))
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    console.error('Error code:', error.code);
    
    // If table doesn't exist, return empty array
    if (error.code === '42P01') {
      console.log('Notifications table does not exist, returning empty array');
      return res.json({
        success: true,
        data: []
      });
    }
    
    // Return empty array for any error instead of 500
    res.json({
      success: true,
      data: []
    });
  }
});

// Mark notification as read
app.put('/api/v1/notifications/:id/read', authenticateToken, async (req, res) => {
  try {
    const notificationId = req.params.id;
    const userId = req.user.id;

    await pool.query(`
      UPDATE notifications 
      SET is_read = true, updated_at = NOW()
      WHERE id = $1 AND (user_id = $2 OR user_id IS NULL)
    `, [notificationId, userId]);

    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
});

// Mark all notifications as read
app.put('/api/v1/notifications/read-all', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    await pool.query(`
      UPDATE notifications 
      SET is_read = true
      WHERE user_id = $1 OR user_id IS NULL
    `, [userId]);

    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ error: 'Failed to mark all notifications as read' });
  }
});

// Create notification (internal use)
app.post('/api/v1/notifications', authenticateToken, async (req, res) => {
  try {
    const { title, message, type, user_id } = req.body;
    const createdBy = req.user.id;

    // If user_id is provided, create for specific user, otherwise create for all users
    if (user_id) {
      const notificationId = uuidv4();
      await pool.query(`
        INSERT INTO notifications (id, title, message, type, user_id, created_by, is_read, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, false, NOW(), NOW())
      `, [notificationId, title, message, type, user_id, createdBy]);
    } else {
      // Create notification for all users
      const usersResult = await pool.query('SELECT id FROM users');
      for (const user of usersResult.rows) {
        const notificationId = uuidv4();
        await pool.query(`
          INSERT INTO notifications (id, title, message, type, user_id, created_by, is_read, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, $6, false, NOW(), NOW())
        `, [notificationId, title, message, type, user.id, createdBy]);
      }
    }

    res.json({ success: true, message: 'Notification created successfully' });
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ error: 'Failed to create notification' });
  }
});

// Email verification endpoint
app.post('/api/v1/auth/verify-email', async (req, res) => {
  try {
    const { email, verificationCode, verification_code } = req.body;
    
    // Handle both parameter names (verificationCode and verification_code)
    const code = verificationCode || verification_code;
    
    if (!email || !code) {
      return res.status(400).json({
        success: false,
        error: 'Email and verification code are required'
      });
    }

    // Find user by email
    const result = await pool.query(
      'SELECT id, email, name, role, created_at, is_active FROM users WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    const user = result.rows[0];
    
    // In a real implementation, you would:
    // 1. Check the verification code from database
    // 2. Verify it hasn't expired
    // 3. Mark the user as verified
    
    // For now, we'll just return success with JWT token
    console.log(`✅ Email verified for: ${email} with code: ${code}`);
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    
    res.json({
      success: true,
      message: 'Email verified successfully',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          createdAt: user.created_at,
          isActive: user.is_active
        },
        token: token,
        expires_in: 86400 // 24 hours
      }
    });
  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to verify email'
    });
  }
});

// Send verification email endpoint
app.post('/api/v1/auth/send-verification', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        error: 'Email is required'
      });
    }

    // Generate verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    console.log('\n🎉 ===========================================');
    console.log(`📧 VERIFICATION CODE FOR: ${email}`);
    console.log(`🔢 CODE: ${verificationCode}`);
    console.log('===========================================\n');
    
    // Send verification email
    if (emailTransporter) {
      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Flow-Space Email Verification',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #333;">Welcome to Flow-Space!</h2>
            <p>Thank you for registering with Flow-Space. Please use the following verification code to complete your registration:</p>
            <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
              <h1 style="color: #007bff; font-size: 32px; margin: 0;">${verificationCode}</h1>
            </div>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request this verification, please ignore this email.</p>
            <hr style="margin: 30px 0;">
            <p style="color: #666; font-size: 14px;">Best regards,<br>The Flow-Space Team</p>
          </div>
        `
      };

      await emailTransporter.sendMail(mailOptions);
      console.log(`📧 Verification email sent to: ${email}`);
    } else {
      console.log('⚠️  Email service not configured - verification email not sent');
      console.log('💡 User can still login using the verification code shown above');
    }
    
    res.json({
      success: true,
      message: 'Verification email sent successfully',
      data: {
        verificationCode: verificationCode // For development - remove in production
      }
    });
  } catch (error) {
    console.error('Send verification email error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send verification email'
    });
  }
});

// Deliverables API endpoints
app.get('/api/v1/deliverables', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    
    let query = `
      SELECT d.*, 
             u1.name as created_by_name,
             u2.name as assigned_to_name,
             s.name as sprint_name
      FROM deliverables d
      LEFT JOIN users u1 ON d.created_by = u1.id
      LEFT JOIN users u2 ON d.assigned_to = u2.id
      LEFT JOIN sprints s ON d.sprint_id = s.id
    `;
    
    let params = [];
    
    // Role-based filtering
    if (userRole === 'teamMember') {
      query += ' WHERE d.assigned_to = $1 OR d.created_by = $1';
      params.push(userId);
    }
    // deliveryLead, clientReviewer and other roles can see all deliverables
    
    query += ' ORDER BY d.created_at DESC';
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error fetching deliverables:', error);
    console.error('Error code:', error.code);
    
    // If table doesn't exist, return empty array
    if (error.code === '42P01') {
      console.log('Deliverables table does not exist, returning empty array');
      return res.json({
        success: true,
        data: []
      });
    }
    
    // Return empty array for any error instead of 500
    res.json({
      success: true,
      data: []
    });
  }
});

app.post('/api/v1/deliverables', authenticateToken, async (req, res) => {
  try {
    const {
      title,
      description,
      definition_of_done,
      evidence_links,
      priority = 'Medium',
      status = 'Draft',
      due_date,
      assigned_to,
      sprint_id
    } = req.body;
    
    const userId = req.user.id;
    
    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }
    
    // Handle definition_of_done - can be string, array, or null
    // Database column is JSON type, so we need valid JSON
    let dodValue = null;
    if (definition_of_done) {
      if (Array.isArray(definition_of_done)) {
        // Array: stringify to JSON array
        dodValue = JSON.stringify(definition_of_done);
      } else if (typeof definition_of_done === 'string') {
        // String: check if it's already valid JSON, otherwise wrap in array
        const trimmed = definition_of_done.trim();
        if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
          // Already JSON format, use as-is
          dodValue = trimmed;
        } else {
          // Plain string: convert to JSON array
          dodValue = JSON.stringify([trimmed]);
        }
      }
    }
    
    // Handle evidence_links - can be array or null
    // Database column might be JSON type, so ensure valid JSON
    let evidenceValue = null;
    if (evidence_links) {
      if (Array.isArray(evidence_links)) {
        // Array: stringify to JSON array
        evidenceValue = JSON.stringify(evidence_links);
      } else if (typeof evidence_links === 'string') {
        // String: check if it's already valid JSON, otherwise wrap in array
        const trimmed = evidence_links.trim();
        if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
          // Already JSON format, use as-is
          evidenceValue = trimmed;
        } else {
          // Plain string: convert to JSON array
          evidenceValue = JSON.stringify([trimmed]);
        }
      }
    }
    
    console.log('📦 Creating deliverable:', { title, dodValue, evidenceValue });
    
    // Try to insert with evidence_links, fallback if column doesn't exist
    let result;
    try {
      result = await pool.query(`
        INSERT INTO deliverables (
          title, description, definition_of_done, priority, status, 
          due_date, created_by, assigned_to, sprint_id, evidence_links
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING *
      `, [
        title, description, dodValue, priority, status,
        due_date, userId, assigned_to, sprint_id, evidenceValue
      ]);
    } catch (columnError) {
      // If evidence_links column doesn't exist, try without it
      if (columnError.code === '42703' || columnError.message.includes('evidence_links')) {
        console.log('⚠️  evidence_links column not found, inserting without it');
        result = await pool.query(`
          INSERT INTO deliverables (
            title, description, definition_of_done, priority, status, 
            due_date, created_by, assigned_to, sprint_id
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          RETURNING *
        `, [
          title, description, dodValue, priority, status,
          due_date, userId, assigned_to, sprint_id
        ]);
      } else {
        throw columnError;
      }
    }
    
    // Create notification for assigned user
    if (assigned_to && assigned_to !== userId) {
      await pool.query(`
        INSERT INTO notifications (title, message, type, user_id, created_by, is_read, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, false, NOW(), NOW())
      `, [
        'New Deliverable Assigned',
        `You have been assigned a new deliverable: ${title}`,
        'deliverable',
        assigned_to
      ]);
    }
    
    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Error creating deliverable:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Error detail:', error.detail);
    console.error('Error hint:', error.hint);
    res.status(500).json({ 
      error: 'Failed to create deliverable',
      details: error.message,
      code: error.code
    });
  }
});

app.put('/api/v1/deliverables/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      definition_of_done,
      priority,
      status,
      due_date,
      assigned_to
    } = req.body;
    
    const userId = req.user.id;
    
    // Check if user can update this deliverable
    const checkResult = await pool.query(
      'SELECT created_by, assigned_to FROM deliverables WHERE id = $1',
      [id]
    );
    
    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deliverable not found' });
    }
    
    const deliverable = checkResult.rows[0];
    const userRole = req.user.role;
    
    // Authorization check
    if (userRole !== 'deliveryLead' && 
        deliverable.created_by !== userId && 
        deliverable.assigned_to !== userId) {
      return res.status(403).json({ error: 'Not authorized to update this deliverable' });
    }
    
    const result = await pool.query(`
      UPDATE deliverables 
      SET title = COALESCE($1, title),
          description = COALESCE($2, description),
          definition_of_done = COALESCE($3, definition_of_done),
          priority = COALESCE($4, priority),
          status = COALESCE($5, status),
          due_date = COALESCE($6, due_date),
          assigned_to = COALESCE($7, assigned_to),
          updated_at = NOW()
      WHERE id = $8
      RETURNING *
    `, [title, description, definition_of_done, priority, status, due_date, assigned_to, id]);
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating deliverable:', error);
    res.status(500).json({ error: 'Failed to update deliverable' });
  }
});

app.delete('/api/v1/deliverables/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // Check if user can delete this deliverable
    const checkResult = await pool.query(
      'SELECT created_by FROM deliverables WHERE id = $1',
      [id]
    );
    
    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deliverable not found' });
    }
    
    // Only delivery leads and creators can delete
    if (userRole !== 'deliveryLead' && checkResult.rows[0].created_by !== userId) {
      return res.status(403).json({ error: 'Not authorized to delete this deliverable' });
    }
    
    await pool.query('DELETE FROM deliverables WHERE id = $1', [id]);
    
    res.json({ success: true, message: 'Deliverable deleted successfully' });
  } catch (error) {
    console.error('Error deleting deliverable:', error);
    res.status(500).json({ error: 'Failed to delete deliverable' });
  }
});

// Enhanced Notifications API endpoints
app.get('/api/v1/notifications/enhanced', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const { type, is_read, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT 
        n.id,
        n.title,
        n.message,
        n.type,
        n.user_id,
        n.is_read,
        n.action_url,
        n.created_at,
        COALESCE(n.updated_at, n.created_at) as updated_at
      FROM notifications n
      WHERE (n.user_id = $1 OR n.user_id IS NULL)
    `;
    
    let params = [userId];
    let paramCount = 1;
    
    // Role-based filtering
    if (userRole === 'clientReviewer') {
      query += ` AND (n.type IN ('deliverable', 'sprint', 'approval', 'review') OR n.user_id IS NULL)`;
    } else if (userRole === 'deliveryLead') {
      query += ` AND (n.type IN ('deliverable', 'sprint', 'team') OR n.user_id IS NULL)`;
    } else if (userRole === 'teamMember') {
      query += ` AND (n.type IN ('deliverable', 'sprint', 'assignment') OR n.user_id IS NULL)`;
    }
    
    // Filter by type
    if (type) {
      paramCount++;
      query += ` AND n.type = $${paramCount}`;
      params.push(type);
    }
    
    // Filter by read status
    if (is_read !== undefined) {
      paramCount++;
      query += ` AND n.is_read = $${paramCount}`;
      params.push(is_read === 'true');
    }
    
    query += ` ORDER BY n.created_at DESC LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error fetching enhanced notifications:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// Create notification with enhanced features
app.post('/api/v1/notifications/enhanced', authenticateToken, async (req, res) => {
  try {
    const { 
      title, 
      message, 
      type, 
      user_id, 
      deliverable_id, 
      sprint_id,
      priority = 'normal',
      action_url,
      metadata
    } = req.body;
    
    const createdBy = req.user.id;
    
    if (!title || !message || !type) {
      return res.status(400).json({ error: 'Title, message, and type are required' });
    }
    
    const notificationId = uuidv4();
    
    // Create notification - only use columns that exist in basic schema
    await pool.query(`
      INSERT INTO notifications (
        id, title, message, type, user_id, action_url,
        is_read, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
    `, [
      notificationId, title, message, type, user_id,
      action_url || null
    ]);
    
    res.status(201).json({
      success: true,
      data: { id: notificationId, message: 'Notification created successfully' }
    });
  } catch (error) {
    console.error('Error creating enhanced notification:', error);
    res.status(500).json({ error: 'Failed to create notification' });
  }
});

// Get notification statistics
app.get('/api/v1/notifications/stats', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    
    let query = `
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN is_read = false THEN 1 END) as unread,
        COUNT(CASE WHEN type = 'deliverable' THEN 1 END) as deliverable_notifications,
        COUNT(CASE WHEN type = 'sprint' THEN 1 END) as sprint_notifications,
        COUNT(CASE WHEN type = 'approval' THEN 1 END) as approval_notifications,
        COUNT(CASE WHEN priority = 'high' AND is_read = false THEN 1 END) as high_priority_unread
      FROM notifications 
      WHERE (user_id = $1 OR user_id IS NULL)
    `;
    
    let params = [userId];
    
    // Role-based filtering
    if (userRole === 'clientReviewer') {
      query += ` AND type IN ('deliverable', 'sprint', 'approval', 'review')`;
    } else if (userRole === 'deliveryLead') {
      query += ` AND type IN ('deliverable', 'sprint', 'team')`;
    } else if (userRole === 'teamMember') {
      query += ` AND type IN ('deliverable', 'sprint', 'assignment')`;
    }
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error fetching notification stats:', error);
    res.status(500).json({ error: 'Failed to fetch notification statistics' });
  }
});

// Dashboard API endpoints
// Get dashboard data
app.get('/api/v1/dashboard', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // Get current deliverables based on user role
    let deliverablesQuery = `
      SELECT d.*, u.name as created_by_name
      FROM deliverables d
      LEFT JOIN users u ON d.created_by = u.id
      WHERE d.status IN ('in_progress', 'pending', 'review')
    `;
    
    if (userRole === 'teamMember') {
      deliverablesQuery += ` AND d.assigned_to = $1`;
    } else if (userRole === 'deliveryLead') {
      deliverablesQuery += ` AND (d.created_by = $1 OR d.assigned_to = $1)`;
    }
    
    deliverablesQuery += ` ORDER BY d.updated_at DESC LIMIT 10`;
    
    const deliverablesResult = await pool.query(deliverablesQuery, [userId]);
    
    // Get recent activity
    const activityQuery = `
      SELECT 
        al.*,
        u.name as user_name,
        d.title as deliverable_title
      FROM activity_log al
      LEFT JOIN users u ON al.user_id = u.id
      LEFT JOIN deliverables d ON al.deliverable_id = d.id
      ORDER BY al.created_at DESC
      LIMIT 20
    `;
    
    const activityResult = await pool.query(activityQuery);
    
    // Get progress statistics
    const statsQuery = `
      SELECT 
        COUNT(*) as total_deliverables,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
        COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        AVG(progress) as avg_progress
      FROM deliverables
      WHERE status != 'cancelled'
    `;
    
    const statsResult = await pool.query(statsQuery);

    // Average sign-off time in days for approved reports
    const avgSignoffQuery = `
      SELECT AVG(EXTRACT(EPOCH FROM (approved_at - submitted_at)) / 86400.0) AS avg_signoff_days
      FROM sign_off_reports
      WHERE status = 'approved'
        AND approved_at IS NOT NULL
        AND submitted_at IS NOT NULL
    `;

    const avgSignoffResult = await pool.query(avgSignoffQuery);
    const avgSignoffDays = avgSignoffResult.rows[0]?.avg_signoff_days;
    
    res.json({
      success: true,
      data: {
        deliverables: deliverablesResult.rows,
        recentActivity: activityResult.rows,
        statistics: {
          ...statsResult.rows[0],
          avg_signoff_days: avgSignoffDays,
        },
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

// Get deliverable progress
app.get('/api/v1/deliverables/:id/progress', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    const result = await pool.query(`
      SELECT id, title, progress, status, updated_at
      FROM deliverables 
      WHERE id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Deliverable not found' });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error fetching deliverable progress:', error);
    res.status(500).json({ error: 'Failed to fetch deliverable progress' });
  }
});

// Update deliverable progress
app.put('/api/v1/deliverables/:id/progress', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { progress, status } = req.body;
    const userId = req.user.id;
    
    if (progress < 0 || progress > 100) {
      return res.status(400).json({ error: 'Progress must be between 0 and 100' });
    }
    
    // Update progress
    const result = await pool.query(`
      UPDATE deliverables 
      SET progress = $1, status = $2, updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `, [progress, status, id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Deliverable not found' });
    }
    
    // Log activity
    await pool.query(`
      INSERT INTO activity_log (user_id, activity_type, activity_title, activity_description, deliverable_id)
      VALUES ($1, 'progress_update', 'Progress Updated', 'Progress updated to ${progress}%', $2)
    `, [userId, id]);
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating deliverable progress:', error);
    res.status(500).json({ error: 'Failed to update deliverable progress' });
  }
});

// Get recent activity
app.get('/api/v1/activity', authenticateToken, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    
    const result = await pool.query(`
      SELECT 
        al.*,
        u.name as user_name,
        d.title as deliverable_title
      FROM activity_log al
      LEFT JOIN users u ON al.user_id = u.id
      LEFT JOIN deliverables d ON al.deliverable_id = d.id
      ORDER BY al.created_at DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error fetching recent activity:', error);
    res.status(500).json({ error: 'Failed to fetch recent activity' });
  }
});

// ==================== DOCUMENT API ENDPOINTS ====================

// Get all documents with search and filtering
app.get('/api/v1/documents', authenticateToken, async (req, res) => {
  try {
    const { search, fileType, uploader, projectId } = req.query;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    let query = `
      SELECT d.*, 
             u.name as uploader_name,
             p.name as project_name
      FROM repository_files d
      LEFT JOIN users u ON d.uploaded_by = u.id
      LEFT JOIN projects p ON d.project_id = p.id
      WHERE 1=1
    `;
    
    let params = [];
    let paramCount = 0;
    
    // Role-based filtering
    if (userRole === 'teamMember') {
      paramCount++;
      query += ` AND (d.uploaded_by = $${paramCount} OR d.project_id IN (
        SELECT project_id FROM project_members WHERE user_id = $${paramCount}
      ))`;
      params.push(userId);
    } else if (userRole === 'deliveryLead') {
      paramCount++;
      query += ` AND (d.uploaded_by = $${paramCount} OR d.project_id IN (
        SELECT project_id FROM project_members WHERE user_id = $${paramCount} AND role IN ('manager', 'owner')
      ))`;
      params.push(userId);
    }
    // clientReviewer and other roles can see all documents
    
    // Search filter
    if (search && search.trim()) {
      paramCount++;
      query += ` AND (d.file_name ILIKE $${paramCount} OR d.description ILIKE $${paramCount} OR d.tags ILIKE $${paramCount})`;
      params.push(`%${search.trim()}%`);
    }
    
    // File type filter
    if (fileType && fileType !== 'all') {
      paramCount++;
      query += ` AND d.file_type = $${paramCount}`;
      params.push(fileType);
    }
    
    // Uploader filter
    if (uploader && uploader.trim()) {
      paramCount++;
      query += ` AND u.name ILIKE $${paramCount}`;
      params.push(`%${uploader.trim()}%`);
    }
    
    // Project filter
    if (projectId && projectId.trim()) {
      paramCount++;
      query += ` AND d.project_id = $${paramCount}`;
      params.push(projectId);
    }
    
    query += ` ORDER BY d.uploaded_at DESC`;
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows.map(row => ({
        id: row.id,
        name: row.file_name,
        fileType: row.file_type,
        uploadDate: row.uploaded_at,
        uploadedBy: row.uploaded_by,
        uploaderName: row.uploader_name,
        size: row.file_size,
        description: row.description || '',
        uploader: row.uploader_name,
        sizeInMB: row.file_size ? (row.file_size / (1024 * 1024)).toFixed(2) : '0',
        filePath: row.file_path,
        tags: row.tags,
        projectName: row.project_name,
        contentHash: row.content_hash
      }))
    });
  } catch (error) {
    console.error('Error fetching documents:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch documents' 
    });
  }
});

// Get single document details
app.get('/api/v1/documents/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    let query = `
      SELECT d.*, 
             u.name as uploader_name,
             p.name as project_name
      FROM repository_files d
      LEFT JOIN users u ON d.uploaded_by = u.id
      LEFT JOIN projects p ON d.project_id = p.id
  WHERE d.id = $1
    `;
    
    let params = [id];
    
    // Role-based filtering
    if (userRole === 'teamMember') {
      query += ` AND (d.uploaded_by = $2 OR d.project_id IN (
        SELECT project_id FROM project_members WHERE user_id = $2
      ))`;
      params.push(userId);
    } else if (userRole === 'deliveryLead') {
      query += ` AND (d.uploaded_by = $2 OR d.project_id IN (
        SELECT project_id FROM project_members WHERE user_id = $2 AND role IN ('manager', 'owner')
      ))`;
      params.push(userId);
    }
    
    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Document not found' 
      });
    }
    
    const document = result.rows[0];
    
    res.json({
      success: true,
      data: {
        id: document.id,
        name: document.file_name,
        fileType: document.file_type,
        uploadDate: document.uploaded_at,
        uploadedBy: document.uploaded_by,
        uploaderName: document.uploader_name,
        size: document.file_size,
        description: document.description || '',
        uploader: document.uploader_name,
        sizeInMB: document.file_size ? (document.file_size / (1024 * 1024)).toFixed(2) : '0',
        filePath: document.file_path,
        tags: document.tags,
        projectName: document.project_name,
        contentHash: document.content_hash
      }
    });
  } catch (error) {
    console.error('Error fetching document:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch document' 
    });
  }
});

// Upload document
app.post('/api/v1/documents', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    console.log('[UPLOAD] File:', req.file);
    console.log('[UPLOAD] Body:', req.body);
    console.log('[UPLOAD] User:', req.user);
    const { description, tags, projectId } = req.body;
    const userId = req.user.id;
    
    if (!req.file) {
      return res.status(400).json({ 
        success: false,
        error: 'No file uploaded' 
      });
    }
    
    const file = req.file;
    const fileExtension = path.extname(file.originalname).toLowerCase();
    const fileType = fileExtension.substring(1); // Remove the dot
    
    // Calculate file hash
    const fileBuffer = fs.readFileSync(file.path);
    const hash = crypto.createHash('sha256').update(fileBuffer).digest('hex');
    
    // Get file size
    const stats = fs.statSync(file.path);
    const fileSize = stats.size;
    
    // Insert document record
    // Note: table has old schema columns (filename VARCHAR, original_filename VARCHAR) and new schema (file_name TEXT)
    // We need to populate all of them for compatibility
    const result = await pool.query(`
      INSERT INTO repository_files (
        project_id, filename, original_filename, file_name, file_path, file_type, file_size, 
        content_hash, uploaded_by, description, tags, 
        uploaded_at, last_modified, is_active
      )
      VALUES ($1, $2::text, $2::text, $2::text, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `, [
      projectId || null,
      file.originalname, // Populates filename, original_filename, and file_name (cast to text)
      file.path,
      fileType,
      fileSize,
      hash,
      userId,
      description || '',
      tags || '',
      new Date().toISOString(),
      new Date().toISOString(),
      true
    ]);
    
    const document = result.rows[0];
    
    // Create notification for project members
    if (projectId) {
      const membersResult = await pool.query(`
        SELECT user_id FROM project_members WHERE project_id = $1 AND user_id != $2
      `, [projectId, userId]);
      
      for (const member of membersResult.rows) {
        await pool.query(`
          INSERT INTO notifications (title, message, type, user_id, is_read, created_at, updated_at)
          VALUES ($1, $2, $3, $4, false, NOW(), NOW())
        `, [
          'New Document Uploaded',
          `A new document "${file.originalname}" has been uploaded to the project`,
          'document',
          member.user_id
        ]);
      }
    }
    
    res.status(201).json({
      success: true,
      data: {
        id: document.id,
        name: document.file_name,
        fileType: document.file_type,
        uploadDate: document.uploaded_at,
        uploadedBy: document.uploaded_by,
        size: document.file_size,
        description: document.description,
        uploader: req.user.name,
        sizeInMB: (document.file_size / (1024 * 1024)).toFixed(2),
        filePath: document.file_path,
        tags: document.tags,
        contentHash: document.content_hash
      }
    });
  } catch (error) {
    console.error('Error uploading document:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      success: false,
      error: error.message || 'Failed to upload document',
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Download document
app.get('/api/v1/documents/:id/download', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`📥 Document download requested for ID: ${id}`);
    
    // Simplified query - just check if document exists
    const query = `
      SELECT d.*, u.name as uploader_name
      FROM repository_files d
      LEFT JOIN users u ON d.uploaded_by::uuid = u.id::uuid
      WHERE d.id::text = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      console.log(`❌ Document not found for download: ${id}`);
      return res.status(404).json({ 
        success: false,
        error: 'Document not found' 
      });
    }
    
    const document = result.rows[0];
    console.log(`✅ Document found for download: ${document.file_name}`);
    
    // Check if file exists
    if (!document.file_path || !fs.existsSync(document.file_path)) {
      console.log(`❌ File not found on server: ${document.file_path}`);
      return res.status(404).json({ 
        success: false,
        error: 'File not found on server' 
      });
    }
    
    console.log(`✅ Streaming file: ${document.file_path}`);
    
    // Set appropriate headers
    res.setHeader('Content-Disposition', `attachment; filename="${document.file_name}"`);
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Length', document.file_size);
    
    // Stream the file
    const fileStream = fs.createReadStream(document.file_path);
    fileStream.pipe(res);
    
    // Log download activity
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'document_download', 'repository_file', $2, $3, NOW())
    `, [userId, id, JSON.stringify({ fileName: document.file_name, fileSize: document.file_size })]);
    
  } catch (error) {
    console.error('Error downloading document:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to download document' 
    });
  }
});

// Document audit history
app.get('/api/v1/documents/:id/audit', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT a.*, u.name as actor_name
      FROM audit_logs a
      LEFT JOIN users u ON a.user_id = u.id
      WHERE a.resource_type = 'repository_file' AND a.resource_id = $1
      ORDER BY a.created_at DESC
    `, [id]);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching document audit:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch audit history' });
  }
});

// Repository audit with filters (project, sprint, deliverable, timeframe)
app.get('/api/v1/repository/audit', authenticateToken, async (req, res) => {
  try {
    const { projectId, sprintId, deliverableId, from, to } = req.query;
    let query = `
      SELECT a.*, u.name as actor_name, d.file_name, d.project_id
      FROM audit_logs a
      LEFT JOIN users u ON a.user_id = u.id
      LEFT JOIN repository_files d ON a.resource_type = 'repository_file' AND a.resource_id = d.id
      WHERE a.resource_type IN ('repository_file','document_download','document_delete')
    `;
    const params = [];
    let p = 0;
    if (projectId) { p++; query += ` AND d.project_id = $${p}`; params.push(projectId); }
    if (sprintId) { p++; query += ` AND (a.details->>'sprintId')::text = $${p}`; params.push(String(sprintId)); }
    if (deliverableId) { p++; query += ` AND (a.details->>'deliverableId')::text = $${p}`; params.push(String(deliverableId)); }
    if (from) { p++; query += ` AND a.created_at >= $${p}`; params.push(new Date(from)); }
    if (to) { p++; query += ` AND a.created_at <= $${p}`; params.push(new Date(to)); }
    query += ' ORDER BY a.created_at DESC LIMIT 200';
    const result = await pool.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching repository audit:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch repository audit' });
  }
});

// Delete document
app.delete('/api/v1/documents/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // Check if user can delete this document
    let query = `
      SELECT d.*, u.name as uploader_name
      FROM repository_files d
      LEFT JOIN users u ON d.uploaded_by = u.id
      WHERE d.id = $1
    `;
    
    let params = [id];
    
    // Role-based filtering - only uploader, delivery leads, or project managers can delete
    if (userRole === 'teamMember') {
      query += ` AND d.uploaded_by = $2`;
      params.push(userId);
    } else if (userRole === 'deliveryLead') {
      query += ` AND (d.uploaded_by = $2 OR d.project_id IN (
        SELECT project_id FROM project_members WHERE user_id = $2 AND role IN ('manager', 'owner')
      ))`;
      params.push(userId);
    }
    
    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Document not found or access denied' 
      });
    }
    
    const document = result.rows[0];
    
    // Soft delete - mark as inactive
    await pool.query(`
      UPDATE repository_files 
      SET is_active = false, last_modified = NOW()
      WHERE id = $1
    `, [id]);
    
    // Log deletion activity
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'document_delete', 'repository_file', $2, $3, NOW())
    `, [userId, id, JSON.stringify({ fileName: document.file_name, fileSize: document.file_size })]);
    
    res.json({
      success: true,
      message: 'Document deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting document:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to delete document' 
    });
  }
});

// Update document metadata
app.put('/api/v1/documents/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { description, tags } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // Check if user can update this document
    let query = `
      SELECT d.* FROM repository_files d
      WHERE d.id = $1
    `;
    
    let params = [id];
    
    // Role-based filtering
    if (userRole === 'teamMember') {
      query += ` AND d.uploaded_by = $2`;
      params.push(userId);
    } else if (userRole === 'deliveryLead') {
      query += ` AND (d.uploaded_by = $2 OR d.project_id IN (
        SELECT project_id FROM project_members WHERE user_id = $2 AND role IN ('manager', 'owner')
      ))`;
      params.push(userId);
    }
    
    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Document not found or access denied' 
      });
    }
    
    // Update document metadata
    await pool.query(`
      UPDATE repository_files 
      SET description = $1, tags = $2, last_modified = NOW()
      WHERE id = $3
    `, [description || '', tags || '', id]);
    
    res.json({
      success: true,
      message: 'Document updated successfully'
    });
  } catch (error) {
    console.error('Error updating document:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to update document' 
    });
  }
});

// Get document preview (for supported file types)
app.get('/api/v1/documents/:id/preview', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`📄 Document preview requested for ID: ${id}`);
    
    // Simplified query - just check if document exists
    const query = `
      SELECT d.*, u.name as uploader_name
      FROM repository_files d
      LEFT JOIN users u ON d.uploaded_by::uuid = u.id::uuid
      WHERE d.id::text = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      console.log(`❌ Document not found: ${id}`);
      return res.status(404).json({ 
        success: false,
        error: 'Document not found' 
      });
    }
    
    const document = result.rows[0];
    console.log(`✅ Document found: ${document.file_name}`);
    
    // Check if file path exists and file is on disk
    if (document.file_path && fs.existsSync(document.file_path)) {
      console.log(`✅ File exists on disk: ${document.file_path}`);
      
      // For text files, read content for preview
      let previewContent = null;
      const textFileTypes = ['txt', 'md', 'json', 'xml', 'csv'];
      if (textFileTypes.includes(document.file_type?.toLowerCase())) {
        try {
          // Read first 100KB for preview (to avoid memory issues with large files)
          const fileContent = fs.readFileSync(document.file_path, 'utf8');
          const maxPreviewLength = 100000; // 100KB
          previewContent = fileContent.length > maxPreviewLength 
            ? fileContent.substring(0, maxPreviewLength) + '\n\n... (Preview truncated. Download to see full content)'
            : fileContent;
          console.log(`✅ Text preview loaded (${previewContent.length} chars)`);
        } catch (readError) {
          console.log(`⚠️ Could not read file content: ${readError.message}`);
        }
      }
      
      // Return file info for preview with actual file data
      res.json({
        success: true,
        data: {
          id: document.id,
          name: document.file_name,
          fileType: document.file_type,
          size: document.file_size,
          sizeInMB: (document.file_size / (1024 * 1024)).toFixed(2),
          uploadDate: document.uploaded_at,
          uploaderName: document.uploader_name,
          description: document.description,
          tags: document.tags,
          previewAvailable: true,
          previewContent: previewContent, // For text files
          downloadUrl: `/api/v1/documents/${id}/download`,
          previewUrl: `/api/v1/documents/${id}/preview`
        }
      });
    } else {
      // File doesn't exist on disk but record exists - return mock preview
      console.log(`⚠️ File not on disk, returning metadata only`);
      
      res.json({
        success: true,
        data: {
          id: document.id,
          name: document.file_name || 'Document',
          fileType: document.file_type || 'pdf',
          size: document.file_size || 0,
          sizeInMB: '0.00',
          uploadDate: document.uploaded_at,
          uploaderName: document.uploader_name || 'Unknown',
          description: document.description || 'No description',
          tags: document.tags || [],
          previewAvailable: false,
          previewMessage: 'Preview not available - file not found on server',
          downloadUrl: `/api/v1/documents/${id}/download`
        }
      });
    }
  } catch (error) {
    console.error('❌ Error getting document preview:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    
    // If table doesn't exist, return friendly error
    if (error.code === '42P01') {
      return res.status(404).json({ 
        success: false,
        error: 'Document repository not available' 
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: 'Failed to get document preview',
      message: error.message 
    });
  }
});

// ===== APPROVAL REQUESTS ENDPOINTS =====

// Get all approval requests
app.get('/api/v1/approval-requests', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    
    let query = `
      SELECT ar.*, u1.name as requested_by_name, u2.name as reviewed_by_name
      FROM approval_requests ar
      LEFT JOIN users u1 ON ar.requested_by = u1.id
      LEFT JOIN users u2 ON ar.reviewed_by = u2.id
      WHERE 1=1
    `;
    
    let params = [];
    
    // Role-based filtering
    if (userRole === 'teamMember') {
      query += ` AND ar.requested_by = $1`;
      params.push(userId);
    } else if (userRole === 'deliveryLead') {
      query += ` AND (ar.requested_by = $1 OR ar.reviewed_by = $1)`;
      params.push(userId);
    }
    
    query += ` ORDER BY ar.created_at DESC`;
    
    const result = await pool.query(query, params);
    
    const approvalRequests = result.rows.map(row => ({
      id: row.id,
      title: row.title,
      description: row.description,
      status: row.status,
      priority: row.priority,
      category: row.category,
      requested_by: row.requested_by,
      requested_by_name: row.requested_by_name,
      requested_at: row.requested_at,
      reviewed_by: row.reviewed_by,
      reviewed_by_name: row.reviewed_by_name,
      reviewed_at: row.reviewed_at,
      review_reason: row.review_reason,
      created_at: row.created_at,
      updated_at: row.updated_at
    }));
    
    res.json({
      success: true,
      data: approvalRequests
    });
  } catch (error) {
    console.error('Get approval requests error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create a new approval request
app.post('/api/v1/approval-requests', authenticateToken, async (req, res) => {
  try {
    const { title, description, priority, category } = req.body;
    const userId = req.user.id;
    
    if (!title) {
      return res.status(400).json({
        success: false,
        error: 'Title is required'
      });
    }
    
    const result = await pool.query(
      `INSERT INTO approval_requests (title, description, status, priority, category, requested_by, requested_at, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        title,
        description || '',
        'pending',
        priority || 'medium',
        category || 'general',
        userId,
        new Date().toISOString(),
        new Date().toISOString(),
        new Date().toISOString()
      ]
    );
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Create approval request error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update approval request status
app.put('/api/v1/approval-requests/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, review_reason } = req.body;
    const userId = req.user.id;
    
    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Status is required'
      });
    }
    
    const result = await pool.query(
      `UPDATE approval_requests 
       SET status = $1, review_reason = $2, reviewed_by = $3, reviewed_at = $4, updated_at = $5
       WHERE id = $6
       RETURNING *`,
      [
        status,
        review_reason || null,
        userId,
        new Date().toISOString(),
        new Date().toISOString(),
        id
      ]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Approval request not found'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Update approval request error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single approval request
app.get('/api/v1/approval-requests/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    let query = `
      SELECT ar.*, u1.name as requested_by_name, u2.name as reviewed_by_name
      FROM approval_requests ar
      LEFT JOIN users u1 ON ar.requested_by = u1.id
      LEFT JOIN users u2 ON ar.reviewed_by = u2.id
      WHERE ar.id = $1
    `;
    
    let params = [id];
    
    // Role-based filtering
    if (userRole === 'teamMember') {
      query += ` AND ar.requested_by = $2`;
      params.push(userId);
    } else if (userRole === 'deliveryLead') {
      query += ` AND (ar.requested_by = $2 OR ar.reviewed_by = $2)`;
      params.push(userId);
    }
    
    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Approval request not found'
      });
    }
    
    const approvalRequest = result.rows[0];
    
    res.json({
      success: true,
      data: {
        id: approvalRequest.id,
        title: approvalRequest.title,
        description: approvalRequest.description,
        status: approvalRequest.status,
        priority: approvalRequest.priority,
        category: approvalRequest.category,
        requested_by: approvalRequest.requested_by,
        requested_by_name: approvalRequest.requested_by_name,
        requested_at: approvalRequest.requested_at,
        reviewed_by: approvalRequest.reviewed_by,
        reviewed_by_name: approvalRequest.reviewed_by_name,
        reviewed_at: approvalRequest.reviewed_at,
        review_reason: approvalRequest.review_reason,
        created_at: approvalRequest.created_at,
        updated_at: approvalRequest.updated_at
      }
    });
  } catch (error) {
    console.error('Get approval request error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== SIGN-OFF REPORTS ENDPOINTS ====================

// Get all sign-off reports with filters
app.get('/api/v1/sign-off-reports', authenticateToken, async (req, res) => {
  try {
    const { status, search, deliverableId, projectId, sprintId, from, to } = req.query;
    const userId = req.user.id;
    const userRole = req.user.role;

    let query = `
      SELECT 
        r.id,
        r.deliverable_id,
        r.created_by,
        r.status,
        r.content,
        r.evidence,
        r.created_at,
        r.updated_at,
        u.name as created_by_name,
        d.title as deliverable_title,
        d.project_id,
        p.name as project_name,
        cr.reviewer_id,
        cr.status as review_status,
        cr.feedback,
        cr.approved_at,
        u2.name as reviewer_name
      FROM sign_off_reports r
      LEFT JOIN users u ON r.created_by = u.id
      LEFT JOIN deliverables d ON r.deliverable_id = d.id
      LEFT JOIN projects p ON d.project_id = p.id
      LEFT JOIN client_reviews cr ON r.id = cr.report_id
      LEFT JOIN users u2 ON cr.reviewer_id = u2.id
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 0;

    // Role-based filtering
    if (userRole === 'teamMember') {
      query += ` AND (r.created_by = $${++paramCount} OR d.assigned_to = $${paramCount})`;
      params.push(userId);
    } else if (userRole === 'clientReviewer') {
      // Client reviewers can see all reports
    }

    if (status) {
      query += ` AND r.status = $${++paramCount}`;
      params.push(status);
    }
    if (deliverableId) {
      query += ` AND r.deliverable_id = $${++paramCount}::uuid`;
      params.push(deliverableId);
    }
    if (projectId) {
      query += ` AND d.project_id = $${++paramCount}::uuid`;
      params.push(projectId);
    }
    if (sprintId) {
      query += ` AND EXISTS (
        SELECT 1 FROM sprint_deliverables sd 
        WHERE sd.deliverable_id = r.deliverable_id AND sd.sprint_id = $${++paramCount}::uuid
      )`;
      params.push(sprintId);
    }
    if (from) {
      query += ` AND r.created_at >= $${++paramCount}`;
      params.push(new Date(from));
    }
    if (to) {
      query += ` AND r.created_at <= $${++paramCount}`;
      params.push(new Date(to));
    }
    if (search) {
      query += ` AND (
        (r.content->>'reportTitle')::text ILIKE $${++paramCount} OR
        (r.content->>'reportContent')::text ILIKE $${paramCount} OR
        d.title ILIKE $${paramCount}
      )`;
      params.push(`%${search}%`);
    }

    query += ' ORDER BY r.created_at DESC';

    const result = await pool.query(query, params);
    
    // Transform results to include review info
    const reportsMap = new Map();
    result.rows.forEach(row => {
      if (!reportsMap.has(row.id)) {
        reportsMap.set(row.id, {
          id: row.id,
          deliverableId: row.deliverable_id,
          deliverableTitle: row.deliverable_title,
          projectId: row.project_id,
          projectName: row.project_name,
          createdBy: row.created_by,
          createdByName: row.created_by_name,
          status: row.status,
          content: row.content || {},
          evidence: row.evidence || [],
          createdAt: row.created_at,
          updatedAt: row.updated_at,
          reviews: []
        });
      }
      if (row.reviewer_id) {
        reportsMap.get(row.id).reviews.push({
          reviewerId: row.reviewer_id,
          reviewerName: row.reviewer_name,
          reviewStatus: row.review_status,
          feedback: row.feedback,
          approvedAt: row.approved_at
        });
      }
    });

    res.json({ 
      success: true, 
      data: Array.from(reportsMap.values())
    });
  } catch (error) {
    console.error('Error fetching sign-off reports:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch sign-off reports' });
  }
});

// Get single sign-off report
app.get('/api/v1/sign-off-reports/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Log view action in audit
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'view_report', 'sign_off_report', $2, '{}', NOW())
    `, [userId, id]);

    const result = await pool.query(`
      SELECT 
        r.*,
        u.name as created_by_name,
        d.title as deliverable_title,
        d.project_id,
        p.name as project_name
      FROM sign_off_reports r
      LEFT JOIN users u ON r.created_by = u.id
      LEFT JOIN deliverables d ON r.deliverable_id = d.id
      LEFT JOIN projects p ON d.project_id = p.id
      WHERE r.id = $1::uuid
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    // Get reviews
    const reviewsResult = await pool.query(`
      SELECT cr.*, u.name as reviewer_name
      FROM client_reviews cr
      LEFT JOIN users u ON cr.reviewer_id = u.id
      WHERE cr.report_id = $1::uuid
      ORDER BY cr.created_at DESC
    `, [id]);

    const report = result.rows[0];
    report.reviews = reviewsResult.rows;

    res.json({ success: true, data: report });
  } catch (error) {
    console.error('Error fetching sign-off report:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch sign-off report' });
  }
});

// Create sign-off report
app.post('/api/v1/sign-off-reports', authenticateToken, async (req, res) => {
  try {
    const { deliverableId, reportTitle, reportContent, sprintIds, sprintPerformanceData, knownLimitations, nextSteps } = req.body;
    const userId = req.user.id;

    if (!deliverableId || !reportTitle || !reportContent) {
      return res.status(400).json({ success: false, error: 'Deliverable ID, report title, and content are required' });
    }

    const content = {
      reportTitle,
      reportContent,
      sprintPerformanceData: sprintPerformanceData || null,
      knownLimitations: knownLimitations || null,
      nextSteps: nextSteps || null,
      sprintIds: sprintIds || []
    };

    const result = await pool.query(`
      INSERT INTO sign_off_reports (deliverable_id, created_by, status, content, created_at, updated_at)
      VALUES ($1::uuid, $2::uuid, 'draft', $3::jsonb, NOW(), NOW())
      RETURNING *
    `, [deliverableId, userId, JSON.stringify(content)]);

    const reportId = result.rows[0].id;

    // Log creation in audit
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'create_report', 'sign_off_report', $2, $3::jsonb, NOW())
    `, [userId, reportId, JSON.stringify({ deliverableId, reportTitle })]);

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error creating sign-off report:', error);
    res.status(500).json({ success: false, error: 'Failed to create sign-off report' });
  }
});

// Update sign-off report
app.put('/api/v1/sign-off-reports/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { reportTitle, reportContent, sprintPerformanceData, knownLimitations, nextSteps, sprintIds } = req.body;
    const userId = req.user.id;

    // Get existing report
    const existingResult = await pool.query(`
      SELECT * FROM sign_off_reports WHERE id = $1::uuid
    `, [id]);

    if (existingResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    const existing = existingResult.rows[0];
    const existingContent = existing.content || {};
    
    const updatedContent = {
      ...existingContent,
      ...(reportTitle && { reportTitle }),
      ...(reportContent && { reportContent }),
      ...(sprintPerformanceData !== undefined && { sprintPerformanceData }),
      ...(knownLimitations !== undefined && { knownLimitations }),
      ...(nextSteps !== undefined && { nextSteps }),
      ...(sprintIds && { sprintIds })
    };

    const result = await pool.query(`
      UPDATE sign_off_reports 
      SET content = $1::jsonb, updated_at = NOW()
      WHERE id = $2::uuid
      RETURNING *
    `, [JSON.stringify(updatedContent), id]);

    // Log update in audit
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'update_report', 'sign_off_report', $2, '{}', NOW())
    `, [userId, id]);

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error updating sign-off report:', error);
    res.status(500).json({ success: false, error: 'Failed to update sign-off report' });
  }
});

// Submit sign-off report
app.post('/api/v1/sign-off-reports/:id/submit', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if delivery lead signature exists in digital_signatures table
    const signatureCheck = await pool.query(`
      SELECT * FROM digital_signatures 
      WHERE report_id = $1::uuid 
      AND signer_id = $2::uuid 
      AND signer_role = 'deliveryLead'
      AND is_valid = true
    `, [id, userId]);

    if (signatureCheck.rows.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Digital signature required. Please sign the report before submitting.' 
      });
    }

    const result = await pool.query(`
      UPDATE sign_off_reports 
      SET status = 'submitted',
          submitted_at = COALESCE(submitted_at, NOW()),
          updated_at = NOW()
      WHERE id = $1::uuid AND created_by = $2::uuid
      RETURNING *
    `, [id, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found or unauthorized' });
    }

    // Log submission in audit
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'submit_report', 'sign_off_report', $2, $3::jsonb, NOW())
    `, [userId, id, JSON.stringify({ signatureVerified: true })]);

    // Create notification for client reviewers
    const clientReviewers = await pool.query(`
      SELECT id FROM users WHERE role = 'clientReviewer' AND is_active = true
    `);
    
    const reportData = result.rows[0];
    const submitter = await pool.query(`SELECT name, email FROM users WHERE id = $1`, [userId]);
    const submitterName = submitter.rows[0]?.name || submitter.rows[0]?.email || 'A user';
    
    for (const reviewer of clientReviewers.rows) {
      const notificationId = uuidv4();
      await pool.query(`
        INSERT INTO notifications (
          id, title, message, type, user_id, action_url, is_read, created_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
      `, [
        notificationId,
        '📋 New Report Submitted for Review',
        `${submitterName} has submitted "${reportData.report_title}" for your review. Please review and approve or request changes.`,
        'report_submission',
        reviewer.id,
        `/report-repository`
      ]);
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error submitting sign-off report:', error);
    res.status(500).json({ success: false, error: 'Failed to submit sign-off report' });
  }
});

// Approve sign-off report
app.post('/api/v1/sign-off-reports/:id/approve', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { comment, digitalSignature } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Only client reviewers can approve
    if (userRole !== 'clientReviewer') {
      return res.status(403).json({ success: false, error: 'Only client reviewers can approve reports' });
    }

    // Require digital signature for approval
    if (!digitalSignature) {
      return res.status(400).json({ 
        success: false, 
        error: 'Digital signature required. Please sign the report before approving.' 
      });
    }

    // Update report status
    const result = await pool.query(`
      UPDATE sign_off_reports 
      SET status = 'approved',
          approved_at = COALESCE(approved_at, NOW()),
          updated_at = NOW()
      WHERE id = $1::uuid
      RETURNING *
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    // Create client review record with digital signature
    await pool.query(`
      INSERT INTO client_reviews (report_id, reviewer_id, status, feedback, approved_at, created_at)
      VALUES ($1::uuid, $2::uuid, 'approved', $3, NOW(), NOW())
    `, [id, userId, comment || null]);
    
    // Store digital signature in the report's content
    const currentContent = result.rows[0].content || {};
    const updatedContent = {
      ...(typeof currentContent === 'object' && currentContent !== null ? currentContent : {}),
      clientSignature: digitalSignature,
      clientSignatureDate: new Date().toISOString(),
      clientSignerId: userId,
    };
    
    await pool.query(`
      UPDATE sign_off_reports 
      SET content = $1::jsonb 
      WHERE id = $2::uuid
    `, [JSON.stringify(updatedContent), id]);
    
    // Also store in digital_signatures table for tracking
    const crypto = require('crypto');
    const signatureHash = crypto.createHash('sha256').update(digitalSignature).digest('hex');
    
    await pool.query(`
      INSERT INTO digital_signatures (
        report_id, signer_id, signer_role, signature_type, 
        signature_data, signature_hash, signed_at, created_at
      )
      VALUES ($1::uuid, $2::uuid, $3, 'manual', $4, $5, NOW(), NOW())
      ON CONFLICT (report_id, signer_id, signer_role) 
      DO UPDATE SET 
        signature_data = EXCLUDED.signature_data,
        signature_hash = EXCLUDED.signature_hash,
        signed_at = NOW()
    `, [id, userId, userRole, digitalSignature, signatureHash]);

    // Log approval in audit
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'approve_report', 'sign_off_report', $2, $3::jsonb, NOW())
    `, [userId, id, JSON.stringify({ comment, signatureVerified: true })]);

    // Create notification for the report creator (delivery lead)
    const reportCreator = result.rows[0].created_by;
    const reviewer = await pool.query(`SELECT name, email FROM users WHERE id = $1`, [userId]);
    const reviewerName = reviewer.rows[0]?.name || reviewer.rows[0]?.email || 'Client Reviewer';
    
    const notificationId = uuidv4();
    await pool.query(`
      INSERT INTO notifications (
        id, title, message, type, user_id, action_url, is_read, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
    `, [
      notificationId,
      '✅ Report Approved!',
      `Great news! ${reviewerName} has approved your report "${result.rows[0].report_title}".${comment ? ' Feedback: ' + comment : ''}`,
      'report_approved',
      reportCreator,
      `/report-repository`
    ]);

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error approving sign-off report:', error);
    res.status(500).json({ success: false, error: 'Failed to approve sign-off report' });
  }
});

// Request changes (decline with feedback)
app.post('/api/v1/sign-off-reports/:id/request-changes', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { changeRequestDetails } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Only client reviewers can request changes
    if (userRole !== 'clientReviewer') {
      return res.status(403).json({ success: false, error: 'Only client reviewers can request changes' });
    }

    if (!changeRequestDetails) {
      return res.status(400).json({ success: false, error: 'Change request details are required' });
    }

    // Update report status
    const result = await pool.query(`
      UPDATE sign_off_reports 
      SET status = 'change_requested', updated_at = NOW()
      WHERE id = $1::uuid
      RETURNING *
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    // Create client review record
    await pool.query(`
      INSERT INTO client_reviews (report_id, reviewer_id, status, feedback, created_at)
      VALUES ($1::uuid, $2::uuid, 'change_requested', $3, NOW())
    `, [id, userId, changeRequestDetails]);

    // Log change request in audit
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'request_changes', 'sign_off_report', $2, $3::jsonb, NOW())
    `, [userId, id, JSON.stringify({ changeRequestDetails })]);

    // Create notification for the report creator (delivery lead)
    const reportCreator = result.rows[0].created_by;
    const reviewer = await pool.query(`SELECT name, email FROM users WHERE id = $1`, [userId]);
    const reviewerName = reviewer.rows[0]?.name || reviewer.rows[0]?.email || 'Client Reviewer';
    
    const notificationId = uuidv4();
    await pool.query(`
      INSERT INTO notifications (
        id, title, message, type, user_id, action_url, is_read, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
    `, [
      notificationId,
      '📝 Changes Requested on Your Report',
      `${reviewerName} has requested changes to "${result.rows[0].report_title}". Changes needed: ${changeRequestDetails}`,
      'report_changes_requested',
      reportCreator,
      `/report-repository`
    ]);

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error requesting changes:', error);
    res.status(500).json({ success: false, error: 'Failed to request changes' });
  }
});

// Get audit history for sign-off report
app.get('/api/v1/sign-off-reports/:id/audit', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // First check if audit_logs table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'audit_logs'
      )
    `);
    
    if (!tableCheck.rows[0].exists) {
      // Table doesn't exist yet, return empty array
      return res.json({ success: true, data: [] });
    }
    
    const result = await pool.query(`
      SELECT 
        a.*,
        u.name as actor_name,
        u.email as actor_email
      FROM audit_logs a
      LEFT JOIN users u ON a.user_id = u.id::uuid
      WHERE a.resource_type = 'sign_off_report' AND a.resource_id = $1
      ORDER BY a.created_at DESC
    `, [id]);

    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching report audit:', error);
    // Return empty array instead of error for better UX
    res.json({ success: true, data: [] });
  }
});

// Track document view for audit
app.post('/api/v1/documents/:id/view', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Log view in audit
    await pool.query(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES ($1, 'view_document', 'repository_file', $2, '{}', NOW())
    `, [userId, id]);

    res.json({ success: true, message: 'View tracked' });
  } catch (error) {
    console.error('Error tracking document view:', error);
    res.status(500).json({ success: false, error: 'Failed to track view' });
  }
});

// ==================== DOCUSIGN ENDPOINTS ====================

// Create DocuSign envelope for a report
app.post('/api/v1/sign-off-reports/:id/docusign/envelope', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { signerEmail, signerName, signerRole } = req.body;
    const userId = req.user.id;

    // Verify report exists
    const reportCheck = await pool.query(`
      SELECT * FROM sign_off_reports WHERE id = $1::uuid
    `, [id]);

    if (reportCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    // In a real implementation, you would call DocuSign API here
    // For now, we'll create a placeholder envelope record
    const envelopeId = `env_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Store envelope information in database
    const result = await pool.query(`
      INSERT INTO docusign_envelopes (
        report_id, envelope_id, status, signer_email, signer_name, 
        signer_role, created_by, sent_at, created_at, updated_at
      )
      VALUES ($1::uuid, $2, 'sent', $3, $4, $5, $6::uuid, NOW(), NOW(), NOW())
      RETURNING *
    `, [id, envelopeId, signerEmail, signerName, signerRole || 'deliveryLead', userId]);

    // Update report with envelope ID
    await pool.query(`
      UPDATE sign_off_reports 
      SET docusign_envelope_id = $1, updated_at = NOW()
      WHERE id = $2::uuid
    `, [envelopeId, id]);

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error creating DocuSign envelope:', error);
    res.status(500).json({ success: false, error: 'Failed to create DocuSign envelope' });
  }
});

// Get DocuSign envelope status
app.get('/api/v1/sign-off-reports/:id/docusign/envelope', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT * FROM docusign_envelopes 
      WHERE report_id = $1::uuid
      ORDER BY created_at DESC
      LIMIT 1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'DocuSign envelope not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error fetching DocuSign envelope:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch DocuSign envelope' });
  }
});

// Update DocuSign envelope status (webhook callback)
app.post('/api/v1/docusign/webhook', async (req, res) => {
  try {
    const { envelopeId, status, signedAt, completedAt } = req.body;
    
    // Update envelope status
    const updates = [];
    const params = [];
    let paramCount = 0;

    if (status) {
      updates.push(`status = $${++paramCount}`);
      params.push(status);
    }
    if (signedAt) {
      updates.push(`signed_at = $${++paramCount}`);
      params.push(new Date(signedAt));
    }
    if (completedAt) {
      updates.push(`completed_at = $${++paramCount}`);
      params.push(new Date(completedAt));
    }

    if (status === 'signed') {
      updates.push(`signed_at = NOW()`);
    }
    if (status === 'completed') {
      updates.push(`completed_at = NOW()`);
    }

    updates.push(`updated_at = NOW()`);
    params.push(envelopeId);

    await pool.query(`
      UPDATE docusign_envelopes 
      SET ${updates.join(', ')}
      WHERE envelope_id = $${paramCount + 1}
    `, params);

    res.json({ success: true, message: 'Envelope status updated' });
  } catch (error) {
    console.error('Error updating DocuSign envelope status:', error);
    res.status(500).json({ success: false, error: 'Failed to update envelope status' });
  }
});

// ==================== EXPORT ENDPOINTS ====================

// Track report export
app.post('/api/v1/sign-off-reports/:id/export', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { exportFormat, exportType, fileSize, fileHash, metadata } = req.body;
    const userId = req.user.id;

    // Verify report exists
    const reportCheck = await pool.query(`
      SELECT * FROM sign_off_reports WHERE id = $1::uuid
    `, [id]);

    if (reportCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    // Check if report_exports table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'report_exports'
      )
    `);

    // Only record export if table exists
    if (tableCheck.rows[0].exists) {
      await pool.query(`
        INSERT INTO report_exports (
          report_id, exported_by, export_format, export_type, 
          file_size, file_hash, metadata, created_at
        )
        VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7::jsonb, NOW())
      `, [id, userId, exportFormat || 'pdf', exportType || 'download', fileSize, fileHash, JSON.stringify(metadata || {})]);
    } else {
      console.log('⚠️ report_exports table does not exist, skipping export tracking');
    }

    res.json({ success: true, message: 'Export completed successfully' });
  } catch (error) {
    console.error('Error tracking report export:', error);
    res.status(500).json({ success: false, error: 'Failed to track export' });
  }
});

// Get export history for a report
app.get('/api/v1/sign-off-reports/:id/exports', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT 
        e.*,
        u.name as exported_by_name,
        u.email as exported_by_email
      FROM report_exports e
      LEFT JOIN users u ON e.exported_by = u.id
      WHERE e.report_id = $1::uuid
      ORDER BY e.created_at DESC
    `, [id]);

    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching export history:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch export history' });
  }
});

// ==================== DIGITAL SIGNATURE ENDPOINTS ====================

// Store digital signature
app.post('/api/v1/sign-off-reports/:id/signature', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { signatureData, signatureType, ipAddress, userAgent } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Verify report exists
    const reportCheck = await pool.query(`
      SELECT * FROM sign_off_reports WHERE id = $1::uuid
    `, [id]);

    if (reportCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    // Generate signature hash
    const crypto = require('crypto');
    const signatureHash = crypto.createHash('sha256').update(signatureData).digest('hex');

    // Store signature in database
    const result = await pool.query(`
      INSERT INTO digital_signatures (
        report_id, signer_id, signer_role, signature_type, 
        signature_data, signature_hash, ip_address, user_agent, 
        signed_at, created_at
      )
      VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8, NOW(), NOW())
      ON CONFLICT (report_id, signer_id, signer_role) 
      DO UPDATE SET 
        signature_data = EXCLUDED.signature_data,
        signature_hash = EXCLUDED.signature_hash,
        signature_type = EXCLUDED.signature_type,
        ip_address = EXCLUDED.ip_address,
        user_agent = EXCLUDED.user_agent,
        signed_at = NOW()
      RETURNING *
    `, [id, userId, userRole, signatureType || 'manual', signatureData, signatureHash, ipAddress, userAgent]);

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error storing digital signature:', error);
    res.status(500).json({ success: false, error: 'Failed to store signature' });
  }
});

// Get digital signatures for a report
app.get('/api/v1/sign-off-reports/:id/signatures', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT 
        ds.*,
        u.name as signer_name,
        u.email as signer_email
      FROM digital_signatures ds
      LEFT JOIN users u ON ds.signer_id = u.id
      WHERE ds.report_id = $1::uuid
      ORDER BY ds.signed_at DESC
    `, [id]);

    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching digital signatures:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch signatures' });
  }
});

// ==================== DOCUSIGN E-SIGNATURE ENDPOINTS ====================
// Temporarily disabled - DocuSign is optional and can be configured later
// Manual signatures work without DocuSign

// const docusignService = require('./docusign-service');

/* DocuSign endpoints temporarily disabled
// Get DocuSign configuration status
app.get('/api/v1/docusign/config', authenticateToken, async (req, res) => {
  try {
    const isConfigured = docusignService.isConfigured();
    
    if (!isConfigured) {
      return res.json({ 
        success: true, 
        data: {
          integration_key: '',
          secret_key: '',
          account_id: '',
          user_id: '',
          base_url: 'https://demo.docusign.net/restapi',
          is_production: false,
          isConfigured: false,
        }
      });
    }

    // Return config without sensitive data
    res.json({ 
      success: true, 
      data: {
        integration_key: docusignService.DOCUSIGN_CONFIG.integrationKey,
        account_id: docusignService.DOCUSIGN_CONFIG.accountId,
        base_url: docusignService.DOCUSIGN_CONFIG.baseUrl,
        is_production: docusignService.DOCUSIGN_CONFIG.isProduction,
        isConfigured: true,
      }
    });
  } catch (error) {
    console.error('Error getting DocuSign config:', error);
    res.status(500).json({ success: false, error: 'Failed to get DocuSign configuration' });
  }
});

// Create DocuSign envelope for report signing
app.post('/api/v1/docusign/envelopes/create', authenticateToken, async (req, res) => {
  try {
    const { reportId, signerEmail, signerName, reportTitle, reportContent } = req.body;
    const userId = req.user.id;

    if (!docusignService.isConfigured()) {
      return res.status(400).json({ 
        success: false, 
        error: 'DocuSign is not configured. Please configure DocuSign credentials in environment variables.' 
      });
    }

    // Verify report exists
    const reportCheck = await pool.query(`
      SELECT * FROM sign_off_reports WHERE id = $1::uuid
    `, [reportId]);

    if (reportCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    // Create DocuSign envelope
    const envelope = await docusignService.createEnvelope({
      reportId,
      signerEmail,
      signerName,
      reportTitle,
      reportContent,
    });

    // Store envelope in database
    await pool.query(`
      INSERT INTO docusign_envelopes (
        id, report_id, envelope_id, signer_email, signer_name, 
        status, created_by, created_at
      )
      VALUES (gen_random_uuid(), $1::uuid, $2, $3, $4, $5, $6::uuid, NOW())
    `, [reportId, envelope.envelopeId, signerEmail, signerName, envelope.status, userId]);

    res.json({ 
      success: true, 
      data: { 
        envelopeId: envelope.envelopeId,
        status: envelope.status,
      }
    });
  } catch (error) {
    console.error('Error creating DocuSign envelope:', error);
    res.status(500).json({ success: false, error: error.message || 'Failed to create DocuSign envelope' });
  }
});

// Get envelope status
app.get('/api/v1/docusign/envelopes/:reportId/status', authenticateToken, async (req, res) => {
  try {
    const { reportId } = req.params;

    // Get envelope from database
    const result = await pool.query(`
      SELECT * FROM docusign_envelopes 
      WHERE report_id = $1::uuid 
      ORDER BY created_at DESC 
      LIMIT 1
    `, [reportId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'No DocuSign envelope found for this report' });
    }

    const envelope = result.rows[0];

    // Get latest status from DocuSign
    try {
      const docusignStatus = await docusignService.getEnvelopeStatus(envelope.envelope_id);
      
      // Update status in database
      await pool.query(`
        UPDATE docusign_envelopes 
        SET 
          status = $1,
          sent_at = $2,
          delivered_at = $3,
          signed_at = $4,
          completed_at = $5,
          updated_at = NOW()
        WHERE envelope_id = $6
      `, [
        docusignStatus.status,
        docusignStatus.sentDateTime,
        docusignStatus.deliveredDateTime,
        docusignStatus.signedDateTime,
        docusignStatus.completedDateTime,
        envelope.envelope_id,
      ]);

      res.json({ success: true, data: { ...envelope, ...docusignStatus } });
    } catch (error) {
      // If DocuSign API fails, return database status
      res.json({ success: true, data: envelope });
    }
  } catch (error) {
    console.error('Error getting envelope status:', error);
    res.status(500).json({ success: false, error: 'Failed to get envelope status' });
  }
});

// Get all envelopes for a report
app.get('/api/v1/docusign/envelopes/:reportId', authenticateToken, async (req, res) => {
  try {
    const { reportId } = req.params;

    const result = await pool.query(`
      SELECT * FROM docusign_envelopes 
      WHERE report_id = $1::uuid 
      ORDER BY created_at DESC
    `, [reportId]);

    res.json({ success: true, data: { envelopes: result.rows } });
  } catch (error) {
    console.error('Error getting envelopes:', error);
    res.status(500).json({ success: false, error: 'Failed to get envelopes' });
  }
});

// Resend envelope
app.post('/api/v1/docusign/envelopes/:envelopeId/resend', authenticateToken, async (req, res) => {
  try {
    const { envelopeId } = req.params;

    const success = await docusignService.resendEnvelope(envelopeId);
    
    if (success) {
      res.json({ success: true, message: 'Envelope notification resent successfully' });
    } else {
      res.status(500).json({ success: false, error: 'Failed to resend envelope' });
    }
  } catch (error) {
    console.error('Error resending envelope:', error);
    res.status(500).json({ success: false, error: 'Failed to resend envelope' });
  }
});

// Void envelope
app.post('/api/v1/docusign/envelopes/:envelopeId/void', authenticateToken, async (req, res) => {
  try {
    const { envelopeId } = req.params;
    const { reason } = req.body;

    await docusignService.voidEnvelope(envelopeId, reason || 'Voided by user');
    
    // Update database
    await pool.query(`
      UPDATE docusign_envelopes 
      SET status = 'voided', decline_reason = $1, updated_at = NOW()
      WHERE envelope_id = $2
    `, [reason, envelopeId]);

    res.json({ success: true, message: 'Envelope voided successfully' });
  } catch (error) {
    console.error('Error voiding envelope:', error);
    res.status(500).json({ success: false, error: 'Failed to void envelope' });
  }
});

// DocuSign webhook endpoint (for status updates)
app.post('/api/v1/docusign/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    const signature = req.headers['x-docusign-signature-1'];
    const webhookSecret = process.env.DOCUSIGN_WEBHOOK_SECRET;

    // Verify webhook signature if secret is configured
    if (webhookSecret && signature) {
      const isValid = docusignService.verifyWebhookSignature(
        req.body.toString(),
        signature,
        webhookSecret
      );

      if (!isValid) {
        return res.status(401).json({ success: false, error: 'Invalid webhook signature' });
      }
    }

    const event = JSON.parse(req.body.toString());
    console.log('📩 DocuSign webhook received:', event.event);

    // Process webhook event
    if (event.event === 'envelope-completed' || event.event === 'recipient-completed') {
      const envelopeId = event.data.envelopeId;
      
      // Update envelope status in database
      await pool.query(`
        UPDATE docusign_envelopes 
        SET 
          status = 'completed',
          completed_at = NOW(),
          updated_at = NOW()
        WHERE envelope_id = $1
      `, [envelopeId]);

      // Get the signed document and store signature
      // You can extend this to download and store the signed document
      console.log('✅ Envelope completed:', envelopeId);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({ success: false, error: 'Failed to process webhook' });
  }
});

// ==================== END DOCUSIGN ENDPOINTS ====================
*/

// ==================== AI RELEASE READINESS ENDPOINTS ====================

// AI-powered release readiness analysis
app.post('/api/v1/release-readiness/analyze', authenticateToken, async (req, res) => {
  try {
    const {
      deliverableId,
      deliverableTitle,
      deliverableDescription,
      definitionOfDone = [],
      evidenceLinks = [],
      sprintIds = [],
      sprintMetrics = {},
      knownLimitations,
    } = req.body;

    // Try OpenAI AI analysis first (if available)
    if (openai) {
      try {
        const prompt = `You are an expert software delivery analyst. Analyze the release readiness of this deliverable and provide structured feedback.

DELIVERABLE INFORMATION:
Title: ${deliverableTitle || 'Untitled'}
Description: ${deliverableDescription || 'No description provided'}

DEFINITION OF DONE (${definitionOfDone.length} items):
${definitionOfDone.length > 0 ? definitionOfDone.map((item, i) => `${i + 1}. ${item}`).join('\n') : 'None provided'}

EVIDENCE LINKS (${evidenceLinks.length} links):
${evidenceLinks.length > 0 ? evidenceLinks.map((link, i) => `${i + 1}. ${link}`).join('\n') : 'None provided'}

SPRINT INFORMATION:
- Sprints Linked: ${sprintIds.length}
- Sprint Metrics: ${JSON.stringify(sprintMetrics, null, 2)}
${knownLimitations ? `- Known Limitations: ${knownLimitations}` : ''}

ANALYSIS REQUIREMENTS:
Analyze this deliverable's readiness for client submission and provide:
1. Overall status: "green" (ready), "amber" (ready with issues), or "red" (not ready)
2. Confidence score (0.0 to 1.0)
3. List of specific issues found
4. Actionable recommendations
5. Risk factors
6. Missing items that should be added
7. Top 3 priority actions
8. A concise AI insights summary (1-2 sentences)

Return ONLY valid JSON in this exact format:
{
  "status": "green|amber|red",
  "confidence": 0.85,
  "issues": ["issue 1", "issue 2"],
  "recommendations": ["recommendation 1", "recommendation 2"],
  "risks": ["risk 1"],
  "missingItems": ["missing item 1"],
  "priorityActions": ["action 1", "action 2", "action 3"],
  "aiInsights": "Your concise summary here"
}`;

        const completion = await openai.chat.completions.create({
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: "You are an expert software delivery analyst specializing in release readiness assessment. Provide accurate, actionable feedback in JSON format only."
            },
            {
              role: "user",
              content: prompt
            }
          ],
          temperature: 0.3,
          max_tokens: 1000,
          response_format: { type: "json_object" }
        });

        const aiResponse = JSON.parse(completion.choices[0].message.content);
        
        // Validate and return AI response
        if (aiResponse.status && ['green', 'amber', 'red'].includes(aiResponse.status)) {
          console.log('✅ AI analysis completed using GPT-3.5-turbo');
          return res.json({
            success: true,
            data: {
              status: aiResponse.status,
              confidence: Math.min(1.0, Math.max(0.0, aiResponse.confidence || 0.8)),
              issues: Array.isArray(aiResponse.issues) ? aiResponse.issues : [],
              recommendations: Array.isArray(aiResponse.recommendations) ? aiResponse.recommendations : [],
              risks: Array.isArray(aiResponse.risks) ? aiResponse.risks : [],
              missingItems: Array.isArray(aiResponse.missingItems) ? aiResponse.missingItems : [],
              priorityActions: Array.isArray(aiResponse.priorityActions) ? aiResponse.priorityActions.slice(0, 3) : [],
              aiInsights: aiResponse.aiInsights || 'AI analysis completed',
            },
          });
        }
      } catch (aiError) {
        console.error('⚠️  OpenAI API error, falling back to rule-based analysis:', aiError.message);
        // Fall through to rule-based analysis
      }
    }

    // Fallback: Rule-based analysis (if OpenAI not available or fails)
    console.log('📊 Using rule-based analysis (fallback)');
    const issues = [];
    const recommendations = [];
    const risks = [];
    const missingItems = [];
    let status = 'green';
    let confidence = 0.9;

    // Analyze Definition of Done
    if (definitionOfDone.length === 0) {
      issues.push('Definition of Done is empty');
      recommendations.push('Add at least 3-5 Definition of Done criteria to ensure quality standards');
      missingItems.push('Definition of Done items');
      status = 'red';
      confidence = 0.7;
    } else if (definitionOfDone.length < 3) {
      issues.push('Definition of Done has fewer than 3 items');
      recommendations.push('Consider adding more DoD criteria for comprehensive quality assurance');
      status = 'amber';
      confidence = 0.8;
    }

    // Analyze Evidence Links
    if (evidenceLinks.length === 0) {
      issues.push('No evidence links provided');
      recommendations.push('Add evidence links: demo, repository, test results, documentation');
      missingItems.push('Evidence links (demo, repo, tests, docs)');
      status = 'red';
      confidence = 0.6;
    } else {
      const hasDemo = evidenceLinks.some(link => 
        link.toLowerCase().includes('demo') || 
        link.toLowerCase().includes('video') ||
        link.toLowerCase().includes('screencast')
      );
      const hasRepo = evidenceLinks.some(link => 
        link.toLowerCase().includes('repo') || 
        link.toLowerCase().includes('github') || 
        link.toLowerCase().includes('gitlab') ||
        link.toLowerCase().includes('bitbucket')
      );
      const hasTests = evidenceLinks.some(link => 
        link.toLowerCase().includes('test') || 
        link.toLowerCase().includes('coverage') ||
        link.toLowerCase().includes('qa')
      );
      const hasDocs = evidenceLinks.some(link => 
        link.toLowerCase().includes('doc') || 
        link.toLowerCase().includes('guide') ||
        link.toLowerCase().includes('wiki')
      );

      if (!hasDemo) {
        issues.push('Missing demo link');
        recommendations.push('Add a demo link or video showing the deliverable in action');
        missingItems.push('Demo link or video');
        if (status === 'green') status = 'amber';
      }
      if (!hasRepo) {
        issues.push('Missing repository link');
        recommendations.push('Add repository link for code review and version control');
        missingItems.push('Repository link');
        if (status === 'green') status = 'amber';
      }
      if (!hasTests) {
        issues.push('Missing test evidence');
        recommendations.push('Add test results or coverage report to demonstrate quality');
        missingItems.push('Test results or coverage report');
        if (status === 'green') status = 'amber';
      }
      if (!hasDocs) {
        issues.push('Missing documentation');
        recommendations.push('Add user guide or technical documentation');
        missingItems.push('Documentation (user guide or technical docs)');
        if (status === 'green') status = 'amber';
      }
    }

    // Analyze Sprint Association
    if (sprintIds.length === 0) {
      issues.push('No sprints linked to deliverable');
      recommendations.push('Link at least one sprint to show development progress and metrics');
      missingItems.push('Linked sprints');
      if (status === 'green') status = 'amber';
    }

    // Analyze Sprint Metrics (if provided)
    if (sprintMetrics && Object.keys(sprintMetrics).length > 0) {
      const testPassRate = sprintMetrics.testPassRate || 0;
      const defectCount = sprintMetrics.defectCount || 0;
      const criticalDefects = sprintMetrics.criticalDefects || 0;

      if (testPassRate < 0.9) {
        issues.push(`Test pass rate is ${(testPassRate * 100).toFixed(0)}%, below recommended 90%`);
        recommendations.push('Improve test pass rate to at least 90% before release');
        if (status === 'green') status = 'amber';
      }

      if (criticalDefects > 0) {
        issues.push(`${criticalDefects} critical defect(s) still open`);
        recommendations.push('Resolve all critical defects before submitting for client review');
        status = 'red';
        confidence = 0.7;
      } else if (defectCount > 5) {
        issues.push(`${defectCount} defects still open`);
        recommendations.push('Consider reducing defect count before release');
        if (status === 'green') status = 'amber';
      }
    }

    // Analyze Known Limitations
    if (knownLimitations && knownLimitations.trim().length > 0) {
      risks.push('Known limitations documented - ensure client is aware');
      recommendations.push('Review known limitations with client before approval');
    }

    // Calculate final status based on issues
    if (issues.length >= 3) {
      status = 'red';
      confidence = 0.7;
    } else if (issues.length >= 1 && status !== 'red') {
      status = 'amber';
      confidence = 0.85;
    }

    // Generate AI Insights
    let aiInsights = '';
    if (status === 'green') {
      aiInsights = '✅ All readiness criteria are met. This deliverable appears ready for client review.';
    } else if (status === 'amber') {
      aiInsights = '💡 Minor improvements recommended. The deliverable is mostly ready, but addressing the suggested items will improve client confidence.';
    } else {
      aiInsights = '⚠️ Multiple readiness gaps detected. Address the critical issues before submission to ensure quality and reduce client feedback cycles.';
    }

    // Priority Actions (top 3 recommendations)
    const priorityActions = recommendations.slice(0, 3);

    res.json({
      success: true,
      data: {
        status,
        confidence,
        issues,
        recommendations,
        risks,
        missingItems,
        priorityActions,
        aiInsights,
      },
    });
  } catch (error) {
    console.error('Error in AI readiness analysis:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to analyze readiness',
    });
  }
});

// Get AI-powered suggestions for missing DoD items
app.post('/api/v1/release-readiness/suggest-items', authenticateToken, async (req, res) => {
  try {
    const { deliverableTitle, deliverableDescription, existingItems = [] } = req.body;

    // AI-generated suggestions based on deliverable context
    const baseSuggestions = [
      'Code review completed',
      'Unit tests passing (>80% coverage)',
      'Integration tests passing',
      'Documentation updated',
      'Demo prepared',
      'Performance benchmarks met',
      'Security review completed',
      'Accessibility standards met',
      'Browser/device compatibility tested',
      'User acceptance testing completed',
    ];

    // Context-aware suggestions based on deliverable type
    const contextSuggestions = [];
    const titleLower = (deliverableTitle || '').toLowerCase();
    const descLower = (deliverableDescription || '').toLowerCase();

    if (titleLower.includes('api') || descLower.includes('api')) {
      contextSuggestions.push('API documentation complete', 'API versioning strategy defined');
    }
    if (titleLower.includes('ui') || titleLower.includes('interface') || descLower.includes('ui')) {
      contextSuggestions.push('UI/UX review completed', 'Responsive design verified');
    }
    if (titleLower.includes('database') || descLower.includes('database')) {
      contextSuggestions.push('Database migration scripts tested', 'Backup and recovery procedures verified');
    }

    // Filter out existing items
    const allSuggestions = [...baseSuggestions, ...contextSuggestions];
    const filteredSuggestions = allSuggestions.filter(
      suggestion => !existingItems.some(existing => 
        existing.toLowerCase().includes(suggestion.toLowerCase()) ||
        suggestion.toLowerCase().includes(existing.toLowerCase())
      )
    );

    res.json({
      success: true,
      data: {
        suggestions: filteredSuggestions.slice(0, 10), // Return top 10
      },
    });
  } catch (error) {
    console.error('Error getting AI suggestions:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get suggestions',
    });
  }
});

// Analyze sprint metrics for readiness
app.post('/api/v1/release-readiness/analyze-sprints', authenticateToken, async (req, res) => {
  try {
    const { sprintMetrics } = req.body;

    if (!Array.isArray(sprintMetrics) || sprintMetrics.length === 0) {
      return res.json({
        success: true,
        data: {
          overallHealth: 'unknown',
          concerns: ['No sprint metrics provided'],
          strengths: [],
        },
      });
    }

    const concerns = [];
    const strengths = [];

    // Analyze each sprint
    for (const sprint of sprintMetrics) {
      const testPassRate = sprint.testPassRate || 0;
      const defectCount = sprint.defectCount || 0;
      const criticalDefects = sprint.criticalDefects || 0;
      const completedPoints = sprint.completedPoints || 0;
      const committedPoints = sprint.committedPoints || 0;

      if (testPassRate >= 0.95) {
        strengths.push(`Sprint ${sprint.sprintName || 'Unknown'}: Excellent test pass rate (${(testPassRate * 100).toFixed(0)}%)`);
      } else if (testPassRate < 0.9) {
        concerns.push(`Sprint ${sprint.sprintName || 'Unknown'}: Low test pass rate (${(testPassRate * 100).toFixed(0)}%)`);
      }

      if (criticalDefects > 0) {
        concerns.push(`Sprint ${sprint.sprintName || 'Unknown'}: ${criticalDefects} critical defect(s) open`);
      }

      if (completedPoints >= committedPoints * 0.9) {
        strengths.push(`Sprint ${sprint.sprintName || 'Unknown'}: Good scope completion (${((completedPoints / committedPoints) * 100).toFixed(0)}%)`);
      } else if (completedPoints < committedPoints * 0.7) {
        concerns.push(`Sprint ${sprint.sprintName || 'Unknown'}: Low scope completion (${((completedPoints / committedPoints) * 100).toFixed(0)}%)`);
      }
    }

    // Determine overall health
    let overallHealth = 'good';
    if (concerns.length > strengths.length * 2) {
      overallHealth = 'poor';
    } else if (concerns.length > strengths.length) {
      overallHealth = 'fair';
    }

    res.json({
      success: true,
      data: {
        overallHealth,
        concerns,
        strengths,
      },
    });
  } catch (error) {
    console.error('Error analyzing sprint metrics:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to analyze sprint metrics',
    });
  }
});

// ==================== END AI RELEASE READINESS ENDPOINTS ====================

app.listen(PORT, () => {
  console.log(`Flow-Space API server running on port ${PORT}`);
});
