const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const EmailService = require('./emailService');
const dbConfig = require('./database-config');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize email service
const emailService = new EmailService();

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection using shared database config
const pool = new Pool(dbConfig);

// Test database connection
pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

// Auth routes
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { email, password, firstName, lastName, company, role } = req.body;
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit code
    
    // Insert user into profiles table
    const result = await pool.query(
      `INSERT INTO profiles (id, first_name, last_name, company, role, email, password_hash, created_at, verification_code, is_verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING id, first_name, last_name, company, role, email, created_at`,
      [userId, firstName, lastName, company, role, email, hashedPassword, new Date().toISOString(), verificationCode, false]
    );
    
    const user = result.rows[0];
    
    // Send verification email
    const emailResult = await emailService.sendVerificationEmail(
      email, 
      `${firstName} ${lastName}`, 
      verificationCode
    );
    
    if (emailResult.success) {
      console.log('✅ Verification email sent successfully');
    } else {
      console.error('❌ Failed to send verification email:', emailResult.error);
    }
    
    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        user_metadata: {
          first_name: user.first_name,
          last_name: user.last_name,
          company: user.company,
          role: user.role,
        },
        created_at: user.created_at,
      },
      emailSent: emailResult.success,
      message: emailResult.success ? 'Account created! Check your email for verification code.' : 'Account created but email sending failed.'
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/auth/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find user by email
    const result = await pool.query(
      'SELECT id, first_name, last_name, company, role, email, password_hash, created_at FROM profiles WHERE email = $1',
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
    
    res.json({
      user: {
        id: user.id,
        email: user.email,
        user_metadata: {
          first_name: user.first_name,
          last_name: user.last_name,
          company: user.company,
          role: user.role,
        },
        created_at: user.created_at,
      }
    });
  } catch (error) {
    console.error('Signin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Deliverables routes
app.get('/api/deliverables', async (req, res) => {
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

app.post('/api/deliverables', async (req, res) => {
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

app.put('/api/deliverables/:id', async (req, res) => {
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
app.get('/api/sprints', async (req, res) => {
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
    
    res.json(sprints);
  } catch (error) {
    console.error('Get sprints error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/sprints', async (req, res) => {
  try {
    const { name, startDate, endDate, plannedPoints, completedPoints, createdBy } = req.body;
    
    const result = await pool.query(
      `INSERT INTO sprints (name, start_date, end_date, planned_points, completed_points, created_by, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [name, startDate, endDate, plannedPoints, completedPoints, createdBy, new Date().toISOString()]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create sprint error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Email verification route
app.post('/api/auth/verify-email', async (req, res) => {
  try {
    const { email, verificationCode } = req.body;
    
    // Find user and check verification code
    const result = await pool.query(
      'SELECT id, verification_code, is_verified FROM profiles WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = result.rows[0];
    
    if (user.is_verified) {
      return res.status(400).json({ error: 'Email already verified' });
    }
    
    if (user.verification_code !== verificationCode) {
      return res.status(400).json({ error: 'Invalid verification code' });
    }
    
    // Update user as verified
    await pool.query(
      'UPDATE profiles SET is_verified = true, verification_code = NULL WHERE email = $1',
      [email]
    );
    
    res.json({ message: 'Email verified successfully' });
  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Password reset request route
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    // Find user
    const result = await pool.query(
      'SELECT id, first_name, last_name FROM profiles WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = result.rows[0];
    const resetToken = uuidv4();
    const resetExpiry = new Date(Date.now() + 3600000); // 1 hour from now
    
    // Store reset token
    await pool.query(
      'UPDATE profiles SET reset_token = $1, reset_token_expiry = $2 WHERE email = $3',
      [resetToken, resetExpiry, email]
    );
    
    // Send password reset email
    const resetLink = `http://localhost:3000/reset-password?token=${resetToken}`;
    const emailResult = await emailService.sendPasswordResetEmail(
      email,
      `${user.first_name} ${user.last_name}`,
      resetLink
    );
    
    if (emailResult.success) {
      res.json({ message: 'Password reset email sent successfully' });
    } else {
      res.status(500).json({ error: 'Failed to send password reset email' });
    }
  } catch (error) {
    console.error('Password reset error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Test SMTP connection route
app.get('/api/test-smtp', async (req, res) => {
  try {
    const isConnected = await emailService.testConnection();
    res.json({ 
      success: isConnected, 
      message: isConnected ? 'SMTP connection successful' : 'SMTP connection failed' 
    });
  } catch (error) {
    console.error('SMTP test error:', error);
    res.status(500).json({ error: 'SMTP test failed', details: error.message });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Flow-Space API is running' });
});

app.listen(PORT, () => {
  console.log(`Flow-Space API server running on port ${PORT}`);
  
  // Test SMTP connection on startup
  emailService.testConnection().then(isConnected => {
    if (isConnected) {
      console.log('✅ Email service ready');
    } else {
      console.log('❌ Email service not available');
    }
  });
});
