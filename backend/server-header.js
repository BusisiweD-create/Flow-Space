// server.js (lines 2–102) — ES Module compatible

// Imports (ES Module syntax)
import jwt from 'jsonwebtoken';
import pool from './dbPool.js'; // your Postgres pool connection
import SendGridEmailService from './sendgridEmailService.js';
import EmailService from './emailService.js';

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

// Authentication middleware
export const authenticateToken = (req, res, next) => {
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

// Default role permissions (in-memory fallback)
const defaultRolePermissions = {
  teammember: new Set(['view_sprints', 'update_tickets', 'update_sprint_status']),
  deliverylead: new Set(['view_sprints', 'update_tickets', 'update_sprint_status']),
  clientreviewer: new Set(['view_sprints'])
};

// Permission middleware
export const requirePermission = (permissionName) => async (req, res, next) => {
  try {
    const role = req.user && req.user.role ? String(req.user.role) : null;
    if (!role) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const normalizedRole = role.toLowerCase();
    const pn = String(permissionName).toLowerCase();

    // Forbid admin update operations
    if ((pn.startsWith('update_')) && ['systemadmin', 'admin', 'system_admin'].includes(normalizedRole)) {
      return res.status(403).json({ error: 'Forbidden: admin cannot update statuses' });
    }

    try {
      const result = await pool.query(
        `
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = $1 AND p.name = $2
        `,
        [req.user.id, permissionName]
      );

      if (result.rows.length === 0) {
        return res.status(403).json({ error: 'Insufficient permissions' });
      }

      next();
    } catch (dbError) {
      if (dbError.code === '42P01') { // table does not exist
        const permissions = defaultRolePermissions[normalizedRole];
        if (permissions && permissions.has(permissionName)) {
          next();
        } else {
          return res.status(403).json({ error: 'Insufficient permissions' });
        }
      } else {
        throw dbError;
      }
    }
  } catch (error) {
    console.error('Permission check error:', error);
    return res.status(500).json({ error: 'Permission check failed' });
  }
};

// Email Configuration - Use SendGrid with SMTP fallback
const emailService = process.env.SENDGRID_API_KEY 
  ? new SendGridEmailService() 
  : new EmailService();

emailService
  .testConnection()
  .then((ok) => {
    if (!ok) {
      console.log('⚠️  Email configuration error: connection failed');
      console.log('💡 Email functionality will be limited until credentials are configured');
    } else {
      console.log('✅ Email service initialized successfully');
    }
  })
  .catch((err) => {
    console.log('⚠️  Email configuration error:', err.message);
    console.log('💡 Email functionality will be limited until credentials are configured');
  });

// TODO: Middleware - Configure CORS for Flutter Web
