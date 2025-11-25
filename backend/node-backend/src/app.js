const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();

// Add this logging middleware at the very beginning
app.use((req, res, next) => {
  console.log(`Incoming request: ${req.method} ${req.url}`);
  next();
});

// Import database configuration
const { testConnection, syncDatabase } = require('./config/database');

// Import models
const { sequelize, User, Notification } = require('./models');
const { QueryTypes, Op } = require('sequelize');

// Import middleware
const { loggingMiddleware } = require('./middleware/loggingMiddleware');
const { performanceMiddleware } = require('./middleware/performanceMiddleware');

// Import routes
const authRoutes = require('./routes/auth');
const { authenticateToken } = require('./middleware/auth');
const deliverablesRoutes = require('./routes/deliverables');
const sprintsRoutes = require('./routes/sprints');
const projectsRoutes = require('./routes/projects');
const analyticsRoutes = require('./routes/analytics');
const auditRoutes = require('./routes/audit');
const fileUploadRoutes = require('./routes/fileUpload');
const monitoringRoutes = require('./routes/monitoring');
const notificationsRoutes = require('./routes/notifications');
const profileRoutes = require('./routes/profile');
const settingsRoutes = require('./routes/settings');
const signoffRoutes = require('./routes/signoff');
const aiRoutes = require('./routes/ai');
const websocketRoutes = require('./routes/websocket');
const systemRoutes = require('./routes/system');
const usersRoutes = require('./routes/users');
const approvalsRoutes = require('./routes/approvals');
const documentsRoutes = require('./routes/documents');

// Import services
const { presenceService } = require('./services/presenceService');
const { notificationService } = require('./services/notificationService');
const analyticsService = require('./services/analyticsService');
const { loggingService } = require('./services/loggingService');
const socketService = require('./services/socketService');
const { databaseNotificationService } = require('./services/DatabaseNotificationService');

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['*'],
  exposedHeaders: ['*']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Custom middleware
app.use(loggingMiddleware);
app.use(performanceMiddleware);
app.use(morgan('combined'));

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/deliverables', deliverablesRoutes);
app.use('/api/v1/sprints', sprintsRoutes);
app.use('/api/v1/projects', projectsRoutes);
app.use('/api/v1/signoff', authenticateToken, signoffRoutes);
app.use('/api/v1/sign-off-reports', authenticateToken, signoffRoutes);
const aiLimiter = rateLimit({ windowMs: 60 * 1000, max: 30 });
app.use('/api/v1/ai', aiLimiter, aiRoutes);
app.use('/api/ai', aiLimiter, aiRoutes);
app.use('/ai', aiLimiter, aiRoutes);
app.use('/api/v1/audit', auditRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/profile', profileRoutes);
app.use('/api/v1/ws', websocketRoutes);
app.use('/api/v1/notifications', notificationsRoutes);
app.use('/api/v1/files', fileUploadRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/monitoring', monitoringRoutes);
app.use('/api/v1/system', systemRoutes);
app.use('/api/v1/users', usersRoutes);
app.use('/api/v1/approvals', approvalsRoutes);
app.use('/api/v1/audit-logs', auditRoutes);
app.use('/api/v1/documents', documentsRoutes);
app.post('/api/v1/iot/ingest', (req, res) => {
  try {
    const { topic, payload, roles, targetRoles, event } = req.body || {};
    const t = typeof topic === 'string' ? topic : '';
    const p = payload !== undefined ? payload : (event ? { event, payload: req.body } : req.body);
    const enriched = { ...(p || {}), roles: roles || targetRoles };
    socketService._handleIotMessage(t || 'iot/ingest', Buffer.from(JSON.stringify(enriched)));
    res.json({ success: true });
  } catch (e) {
    res.status(400).json({ success: false, error: 'invalid payload' });
  }
});

// Sprint tickets compatibility endpoints (minimal implementation to unblock UI)
app.get('/api/v1/sprints/:id/tickets', async (req, res) => {
  try {
    res.json({ success: true, data: [] });
  } catch (error) {
    console.error('Error fetching sprint tickets:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/tickets', async (req, res) => {
  try {
    const { sprintId, title, description, assignee, priority, type } = req.body || {};
    if (!sprintId || !title || !description) {
      return res.status(400).json({ success: false, error: 'Sprint ID, title, and description are required' });
    }
    const now = new Date().toISOString();
    const ticket = {
      id: `T-${Date.now()}`,
      sprint_id: sprintId,
      summary: title,
      description,
      status: 'To Do',
      assignee: assignee || null,
      priority: priority || 'medium',
      issue_type: type || 'task',
      created_at: now,
      updated_at: now,
    };
    res.status(201).json({ success: true, data: ticket });
  } catch (error) {
    console.error('Error creating ticket:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Public alias for system routes
app.use('/system', systemRoutes);

// Health check endpoints
app.get('/', (req, res) => {
  res.json({ message: 'Hackathon Backend API is running' });
});

app.get('/health', (req, res) => {
  const iotEnabled = String(process.env.IOT_ENABLED || '').toLowerCase() === 'true';
  res.json({ status: 'healthy', iot: { enabled: iotEnabled } });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong!'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Database connection and server startup
const PORT = process.env.PORT || 8000;

async function startServer() {
  try {
    // Test database connection
    await sequelize.authenticate();
    await syncDatabase({ alter: true });
    console.log('✅ Database connection established successfully');
    
    // Sync database (use with caution in production)
    if (process.env.NODE_ENV === 'development') {
      // Use safe sync instead of alter to prevent infinite loops
      await sequelize.sync({ force: false });
      console.log('✅ Database synchronized safely');
    }
    
    // Start server first to ensure it's listening
    const server = app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📚 API Documentation: http://localhost:${PORT}/api-docs`);
      
      // Initialize Socket.io server
      socketService.initialize(server);
      console.log('✅ Socket.io server initialized for real-time communication');
      console.log('🔧 IoT MQTT status:', {
        enabled: String(process.env.IOT_ENABLED || '').toLowerCase() === 'true',
        url: process.env.IOT_MQTT_URL || ''
      });
      
      // Initialize Database Notification Service
      const dbConnectionString = process.env.DATABASE_URL;
      if (dbConnectionString) {
        databaseNotificationService.initialize(dbConnectionString)
          .then(() => {
            console.log('✅ Database notification service initialized');
            
            // Integrate socket service with database notification service
            databaseNotificationService.setSocketService(socketService);
            console.log('✅ Real-time services integrated successfully');
          })
          .catch(error => {
            console.error('❌ Failed to initialize database notification service:', error);
          });
      } else {
        console.warn('⚠️ DATABASE_URL not set, database notification service disabled');
      }
      
      // Start background services after server is listening
      // Analytics service is now started on-demand via API endpoints to prevent server overload
      loggingService.start().catch(error => {
        console.error('Failed to start logging service:', error);
      });
      
  console.log('✅ Background services started successfully');
  console.log(`🔗 Access your backend at: http://localhost:${PORT}/`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`🔗 API v1 endpoints: http://localhost:${PORT}/api/v1/`);
      console.log(`🔌 WebSocket endpoint: ws://localhost:${PORT}`);
      console.log(`🔧 IoT enabled: ${String(process.env.IOT_ENABLED || '').toLowerCase() === 'true'}`);
      const hasOpenAI = !!process.env.OPENAI_API_KEY;
      console.log(hasOpenAI ? '✅ OpenAI API key detected' : '⚠️ OpenAI API key missing');
      if (hasOpenAI) {
        console.log(`🤖 AI chat endpoint ready: http://localhost:${PORT}/api/v1/ai/chat`);
      } else {
        console.warn('AI features disabled until OPENAI_API_KEY is set');
      }

      const sendPendingReportReminders = async () => {
        try {
          const dueReports = await sequelize.query(
            "SELECT id, created_by, status, content, updated_at FROM sign_off_reports WHERE status = 'submitted' AND updated_at <= NOW() - INTERVAL '1 day'",
            { type: QueryTypes.SELECT }
          );

          if (!dueReports || dueReports.length === 0) return;

          const reviewers = await User.findAll({ where: { role: { [Op.in]: ['clientReviewer', 'ClientReviewer', 'clientreviewer'] }, is_active: true } });
          if (!reviewers || reviewers.length === 0) return;

          for (const report of dueReports) {
            const content = typeof report.content === 'string' ? (() => { try { return JSON.parse(report.content); } catch { return {}; } })() : (report.content || {});
            const title = content.reportTitle || content.report_title || 'Sign-Off Report';

            // Prevent duplicate reminders by checking existing notifications in the last 2 days
            const recentReminders = await sequelize.query(
              "SELECT id FROM notifications WHERE type = 'approval' AND message LIKE :msgPattern AND created_at >= NOW() - INTERVAL '2 days'",
              { type: QueryTypes.SELECT, replacements: { msgPattern: `%${title}%` } }
            );
            if (recentReminders && recentReminders.length > 0) continue;

            const notifications = reviewers.map((client) => ({
              recipient_id: client.id,
              sender_id: report.created_by || null,
              type: 'approval',
              message: `Reminder: Please review and approve or request changes for "${title}"`,
              payload: {
                report_id: report.id,
                report_title: title,
                action_url: `/enhanced-client-review/${report.id}`,
              },
              is_read: false,
              created_at: new Date(),
            }));

            await Notification.bulkCreate(notifications);
          }
        } catch (err) {
          console.error('Error sending pending report reminders:', err);
        }
      };

      sendPendingReportReminders();
      setInterval(sendPendingReportReminders, 30 * 60 * 1000);
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('🛑 Received SIGTERM, shutting down gracefully');
  
  // Stop background services
  await analyticsService.stop();
  await loggingService.stop();
  
  // Close database connection
  await sequelize.close();
  
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('🛑 Received SIGINT, shutting down gracefully');
  
  // Stop background services
  await analyticsService.stop();
  await loggingService.stop();
  
  // Close database connection
  await sequelize.close();
  
  process.exit(0);
});

// Start the server
startServer();

module.exports = app;