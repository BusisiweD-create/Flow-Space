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
const { sequelize } = require('./models');

// Import middleware
const { loggingMiddleware } = require('./middleware/loggingMiddleware');
const { performanceMiddleware } = require('./middleware/performanceMiddleware');

// Import routes
const authRoutes = require('./routes/auth');
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
const websocketRoutes = require('./routes/websocket');
const systemRoutes = require('./routes/system');
const usersRoutes = require('./routes/users');
const approvalsRoutes = require('./routes/approvals');

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
app.use('/api/v1/signoff', signoffRoutes);
app.use('/api/v1/sign-off-reports', signoffRoutes);
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

// Tickets routes
const ticketsRoutes = require('./routes/tickets');
const { Ticket } = require('./models');
app.use('/api/v1/tickets', ticketsRoutes);
app.get('/api/v1/sprints/:sprintId/tickets', async (req, res) => {
  try {
    const { sprintId } = req.params;
    const tickets = await Ticket.findAll({
      where: { sprint_id: parseInt(sprintId) },
      order: [['created_at', 'DESC']],
    });
    res.json({ success: true, data: tickets });
  } catch (error) {
    console.error('Error fetching sprint tickets:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Public alias for system routes
app.use('/system', systemRoutes);

// Health check endpoints
app.get('/', (req, res) => {
  res.json({ message: 'Hackathon Backend API is running' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
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