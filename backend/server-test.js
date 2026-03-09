require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'flow_space',
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 5432,
});

// Middleware
app.use(cors());
app.use(express.json());

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
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});

// Get projects
app.get('/api/v1/projects', authenticateToken, async (req, res) => {
  try {
    console.log('📊 Fetching projects for user:', req.user.userId);
    const userId = req.user.userId;
    
    const result = await pool.query(`
      SELECT id, project_id, project_key, project_name, project_type, created_at
      FROM jira_projects 
      WHERE user_id = $1 
      ORDER BY created_at DESC
    `, [userId]);
    
    console.log(`✅ Found ${result.rows.length} projects`);
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ Error fetching projects:', error);
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
});

// Get sprints
app.get('/api/v1/sprints', authenticateToken, async (req, res) => {
  try {
    console.log('📊 Fetching sprints for user:', req.user.userId);
    const userId = req.user.userId;
    
    const result = await pool.query(`
      SELECT id, name, description, start_date, end_date, status, created_by, created_at, updated_at
      FROM sprints 
      WHERE created_by = $1 
      ORDER BY created_at DESC
    `, [userId]);
    
    console.log(`✅ Found ${result.rows.length} sprints`);
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ Error fetching sprints:', error);
    res.status(500).json({ error: 'Failed to fetch sprints' });
  }
});

// Create project
app.post('/api/v1/projects', authenticateToken, async (req, res) => {
  try {
    console.log('📝 Creating project for user:', req.user.userId);
    const userId = req.user.userId;
    const { name, key, description, projectType } = req.body;
    
    const result = await pool.query(`
      INSERT INTO jira_projects (user_id, project_id, project_key, project_name, project_type, created_at)
      VALUES ($1, $2, $3, $4, $5, NOW())
      RETURNING id, project_id, project_key, project_name, project_type, created_at
    `, [userId, Date.now().toString(), key, name, projectType || 'software']);
    
    console.log(`✅ Created project: ${result.rows[0].project_name}`);
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Error creating project:', error);
    res.status(500).json({ error: 'Failed to create project' });
  }
});

// Start server
async function startServer() {
  try {
    // Test database connection
    await pool.query('SELECT NOW()');
    console.log('✅ Connected to PostgreSQL database');
    
    app.listen(PORT, () => {
      console.log(`🚀 Test Server running on http://localhost:${PORT}`);
      console.log(`📊 Health check: http://localhost:${PORT}/health`);
      console.log(`🔐 Projects: http://localhost:${PORT}/api/v1/projects`);
      console.log(`🏃 Sprints: http://localhost:${PORT}/api/v1/sprints`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
