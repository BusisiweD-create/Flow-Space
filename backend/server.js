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
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3001;

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

// Email Configuration
const emailTransporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Middleware
app.use(cors());
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
      return res.status(401).json({ 
        success: false,
        error: 'Invalid credentials' 
      });
    }
    
    const user = result.rows[0];
    
    // Check if user is active
    if (!user.is_active) {
      return res.status(401).json({ 
        success: false,
        error: 'Account is deactivated' 
      });
    }
    
    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
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

// Deliverables routes
app.get('/api/v1/deliverables', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT d.*, p.first_name, p.last_name
      FROM deliverables d
      LEFT JOIN profiles p ON d.assigned_to = p.id
      ORDER BY d.created_at DESC
    `);
    
    const deliverables = result.rows.map(row => ({
      id: row.id,
      title: row.title,
      description: row.description,
      definition_of_done: row.definition_of_done,
      status: row.status,
      assigned_to: row.assigned_to,
      created_by: row.created_by,
      sprint_id: row.sprint_id,
      priority: row.priority,
      due_date: row.due_date,
      created_at: row.created_at,
      updated_at: row.updated_at,
      assigned_user_name: row.first_name ? `${row.first_name} ${row.last_name}` : null,
    }));
    
    res.json(deliverables);
  } catch (error) {
    console.error('Get deliverables error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/deliverables', async (req, res) => {
  try {
    const { title, description, definitionOfDone, status, assignedTo, createdBy } = req.body;
    
    const result = await pool.query(
      `INSERT INTO deliverables (title, description, definition_of_done, status, assigned_to, created_by, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [title, description, definitionOfDone, status, assignedTo, createdBy, new Date().toISOString()]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create deliverable error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/v1/deliverables/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    await pool.query(
      'UPDATE deliverables SET status = $1, updated_at = $2 WHERE id = $3',
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
      SELECT s.*, p.first_name, p.last_name
      FROM sprints s
      LEFT JOIN profiles p ON s.created_by = p.id
      ORDER BY s.start_date DESC
    `);
    
    const sprints = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      description: row.description,
      start_date: row.start_date,
      end_date: row.end_date,
      planned_points: row.planned_points,
      completed_points: row.completed_points,
      status: row.status,
      created_by: row.created_by,
      created_at: row.created_at,
      updated_at: row.updated_at,
      created_by_name: row.first_name ? `${row.first_name} ${row.last_name}` : null,
    }));
    
    res.json({
      success: true,
      data: sprints
    });
  } catch (error) {
    console.error('Get sprints error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/sprints', authenticateToken, async (req, res) => {
  try {
    const { name, description, start_date, end_date, plannedPoints, completedPoints } = req.body;
    const userId = req.user.id;
    
    if (!name || !start_date || !end_date) {
      return res.status(400).json({
        success: false,
        error: 'Name, start_date, and end_date are required'
      });
    }
    
    const result = await pool.query(
      `INSERT INTO sprints (name, description, start_date, end_date, planned_points, completed_points, created_by, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [name, description || '', start_date, end_date, plannedPoints || 0, completedPoints || 0, userId, new Date().toISOString(), new Date().toISOString()]
    );
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Create sprint error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Sprint board endpoints
app.get('/api/v1/sprints/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT s.*, p.first_name, p.last_name
      FROM sprints s
      LEFT JOIN profiles p ON s.created_by = p.id
      WHERE s.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Sprint not found' });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Get sprint error:', error);
    res.status(500).json({ error: 'Internal server error' });
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
    const result = await pool.query(`
      SELECT p.*, u.name as created_by_name
      FROM projects p
      LEFT JOIN users u ON p.created_by = u.id
      ORDER BY p.created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Get projects error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

app.post('/api/v1/projects', authenticateToken, async (req, res) => {
  try {
    const { name, key, description, projectType, start_date, end_date } = req.body;
    const userId = req.user.id;
    
    if (!name || !key) {
      return res.status(400).json({ 
        success: false,
        error: 'Name and key are required' 
      });
    }
    
    const projectId = uuidv4();
    const result = await pool.query(`
      INSERT INTO projects (id, name, key, description, project_type, created_by, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `, [
      projectId, 
      name, 
      key,
      description || '', 
      projectType || 'software',
      userId, 
      new Date().toISOString(), 
      new Date().toISOString()
    ]);
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Create project error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Flow-Space API is running' });
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

app.post('/api/v1/tickets', async (req, res) => {
  try {
    const { sprintId, title, description, assignee, priority, type } = req.body;
    const userId = req.user?.id || '80ebe775-1837-4ff5-a0a5-faabd46e0b96'; // Default user for now
    
    if (!sprintId || !title || !description) {
      return res.status(400).json({ 
        success: false,
        error: 'Sprint ID, title, and description are required' 
      });
    }
    
    const ticketId = `TICK-${Date.now()}`;
    const ticketKey = `FLOW-${Date.now()}`;
    const result = await pool.query(`
      INSERT INTO tickets (ticket_id, ticket_key, summary, description, status, assignee, reporter, sprint_id, priority, issue_type, user_id, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *
    `, [
      ticketId, 
      ticketKey,
      title, 
      description, 
      'To Do', 
      assignee, 
      userId, 
      sprintId, 
      priority || 'medium', 
      type || 'task',
      userId, // Add user_id field
      new Date().toISOString(), 
      new Date().toISOString()
    ]);
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Create ticket error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

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
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Status is required'
      });
    }

    // Validate status values
    const validStatuses = ['planning', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
      });
    }

    const result = await pool.query(`
      UPDATE sprints
      SET status = $1, updated_at = $2
      WHERE id = $3
      RETURNING *
    `, [status, new Date().toISOString(), sprintId]);

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
    res.status(500).json({
      success: false,
      error: 'Internal server error'
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
    res.status(500).json({ error: 'Failed to fetch notifications' });
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
      SET is_read = true, updated_at = NOW()
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

    // In a real implementation, you would:
    // 1. Check the verification code from database
    // 2. Verify it hasn't expired
    // 3. Mark the user as verified
    
    // For now, we'll just return success
    console.log(`✅ Email verified for: ${email} with code: ${code}`);
    
    res.json({
      success: true,
      message: 'Email verified successfully'
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
    const mailOptions = {
      from: process.env.EMAIL_USER || 'dhlaminibusisiwe30@gmail.com',
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
    } else if (userRole === 'deliveryLead') {
      query += ' WHERE d.created_by = $1';
      params.push(userId);
    }
    // clientReviewer and other roles can see all deliverables
    
    query += ' ORDER BY d.created_at DESC';
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error fetching deliverables:', error);
    res.status(500).json({ error: 'Failed to fetch deliverables' });
  }
});

app.post('/api/v1/deliverables', authenticateToken, async (req, res) => {
  try {
    const {
      title,
      description,
      definition_of_done,
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
    
    const result = await pool.query(`
      INSERT INTO deliverables (
        title, description, definition_of_done, priority, status, 
        due_date, created_by, assigned_to, sprint_id
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [
      title, description, definition_of_done, priority, status,
      due_date, userId, assigned_to, sprint_id
    ]);
    
    // Create notification for assigned user
    if (assigned_to && assigned_to !== userId) {
      await pool.query(`
        INSERT INTO notifications (title, message, type, user_id, created_by, is_read, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, false, NOW(), NOW())
      `, [
        'New Deliverable Assigned',
        `You have been assigned a new deliverable: ${title}`,
        'deliverable',
        assigned_to,
        userId
      ]);
    }
    
    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating deliverable:', error);
    res.status(500).json({ error: 'Failed to create deliverable' });
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
      SELECT n.*, 
             u.name as created_by_name,
             d.title as deliverable_title,
             s.name as sprint_name
      FROM notifications n
      LEFT JOIN users u ON n.created_by = u.id
      LEFT JOIN deliverables d ON n.deliverable_id = d.id
      LEFT JOIN sprints s ON n.sprint_id = s.id
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
    
    // Create notification
    await pool.query(`
      INSERT INTO notifications (
        id, title, message, type, user_id, created_by, 
        deliverable_id, sprint_id, priority, action_url, metadata,
        is_read, created_at, updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, false, NOW(), NOW())
    `, [
      notificationId, title, message, type, user_id, createdBy,
      deliverable_id, sprint_id, priority, action_url, 
      metadata ? JSON.stringify(metadata) : null
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
    
    res.json({
      success: true,
      data: {
        deliverables: deliverablesResult.rows,
        recentActivity: activityResult.rows,
        statistics: statsResult.rows[0]
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
      WHERE d.is_active = true
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
      WHERE d.id = $1 AND d.is_active = true
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
    const result = await pool.query(`
      INSERT INTO repository_files (
        project_id, file_name, file_path, file_type, file_size, 
        content_hash, uploaded_by, description, tags, 
        uploaded_at, last_modified, is_active
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `, [
      projectId || null,
      file.originalname,
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
          INSERT INTO notifications (title, message, type, user_id, created_by, is_read, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, false, NOW(), NOW())
        `, [
          'New Document Uploaded',
          `A new document "${file.originalname}" has been uploaded to the project`,
          'document',
          member.user_id,
          userId
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
    res.status(500).json({ 
      success: false,
      error: 'Failed to upload document' 
    });
  }
});

// Download document
app.get('/api/v1/documents/:id/download', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // Get document details with authorization check
    let query = `
      SELECT d.*, u.name as uploader_name
      FROM repository_files d
      LEFT JOIN users u ON d.uploaded_by = u.id
      WHERE d.id = $1 AND d.is_active = true
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
        error: 'Document not found or access denied' 
      });
    }
    
    const document = result.rows[0];
    
    // Check if file exists
    if (!fs.existsSync(document.file_path)) {
      return res.status(404).json({ 
        success: false,
        error: 'File not found on server' 
      });
    }
    
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
      WHERE d.id = $1 AND d.is_active = true
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
      WHERE d.id = $1 AND d.is_active = true
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
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // Get document details with authorization check
    let query = `
      SELECT d.*, u.name as uploader_name
      FROM repository_files d
      LEFT JOIN users u ON d.uploaded_by = u.id
      WHERE d.id = $1 AND d.is_active = true
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
        error: 'Document not found or access denied' 
      });
    }
    
    const document = result.rows[0];
    
    // Check if file exists
    if (!fs.existsSync(document.file_path)) {
      return res.status(404).json({ 
        success: false,
        error: 'File not found on server' 
      });
    }
    
    // For now, return file info for preview
    // In a real implementation, you would generate thumbnails or extract text content
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
        previewAvailable: ['pdf', 'txt', 'md', 'json', 'xml'].includes(document.file_type.toLowerCase()),
        downloadUrl: `/api/v1/documents/${id}/download`
      }
    });
  } catch (error) {
    console.error('Error getting document preview:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to get document preview' 
    });
  }
});

app.listen(PORT, () => {
  console.log(`Flow-Space API server running on port ${PORT}`);
});
