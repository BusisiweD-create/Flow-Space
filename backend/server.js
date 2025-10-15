const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3001;

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

// Middleware
app.use(cors());
app.use(express.json());

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

app.listen(PORT, () => {
  console.log(`Flow-Space API server running on port ${PORT}`);
});
