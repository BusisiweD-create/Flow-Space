const socketIO = require('socket.io');
const jwt = require('jsonwebtoken');
const { loggingService } = require('./loggingService');

class SocketService {
  constructor() {
    this.io = null;
    this.connectedUsers = new Map();
    this.rooms = new Map();
  }

  initialize(server) {
    this.io = socketIO(server, {
      cors: {
        origin: "*",
        methods: ["GET", "POST"],
        credentials: true
      }
    });

    this.io.use(this.authenticateSocket.bind(this));
    this.io.on('connection', this.handleConnection.bind(this));

    console.log('Socket.io server initialized');
  }

  async authenticateSocket(socket, next) {
    try {
      const token = socket.handshake.auth.token || socket.handshake.query.token;
      
      if (!token) {
        return next(new Error('Authentication error: No token provided'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret');
      socket.userId = decoded.userId;
      socket.userRole = decoded.role;
      socket.email = decoded.email;
      
      next();
    } catch (error) {
      console.error('Socket authentication failed:', error.message);
      next(new Error('Authentication error: Invalid token'));
    }
  }

  handleConnection(socket) {
    const { userId, userRole, email } = socket;
    
    console.log('User connected via WebSocket:', { 
      userId, 
      userRole, 
      email,
      socketId: socket.id 
    });

    // Add user to connected users map
    this.connectedUsers.set(userId, {
      socketId: socket.id,
      userId,
      userRole,
      email,
      connectedAt: new Date(),
      lastActivity: new Date()
    });

    // Join user to their personal room
    socket.join(`user:${userId}`);
    
    // Join user to role-based rooms
    socket.join(`role:${userRole}`);
    
    // Join user to global room
    socket.join('global');

    // Handle real-time events
    this.setupEventHandlers(socket);

    // Handle disconnection
    socket.on('disconnect', (reason) => {
      console.log('User disconnected from WebSocket:', { 
        userId, 
        email,
        reason,
        socketId: socket.id 
      });
      
      this.connectedUsers.delete(userId);
      
      // Broadcast user offline status
      socket.to('global').emit('user_offline', { 
        userId, 
        email,
        timestamp: new Date()
      });
    });

    // Broadcast user online status
    socket.to('global').emit('user_online', { 
      userId, 
      email,
      userRole,
      timestamp: new Date()
    });

    // Send connection confirmation
    socket.emit('connected', { 
      message: 'Successfully connected to real-time server',
      userId,
      userRole,
      timestamp: new Date()
    });
  }

  setupEventHandlers(socket) {
    const { userId, userRole, email } = socket;

    // Deliverable events
    socket.on('deliverable_created', (data) => {
      console.log('Deliverable created via WebSocket:', { 
        userId, 
        email,
        deliverableId: data.id 
      });
      
      // Broadcast to all users except sender
      socket.broadcast.emit('deliverable_created', {
        ...data,
        createdBy: userId,
        timestamp: new Date()
      });
    });

    socket.on('deliverable_updated', (data) => {
      console.log('Deliverable updated via WebSocket:', { 
        userId, 
        email,
        deliverableId: data.id 
      });
      
      // Broadcast to all users
      this.io.emit('deliverable_updated', {
        ...data,
        updatedBy: userId,
        timestamp: new Date()
      });
    });

    socket.on('deliverable_deleted', (data) => {
      console.log('Deliverable deleted via WebSocket:', { 
        userId, 
        email,
        deliverableId: data.id 
      });
      
      // Broadcast to all users
      this.io.emit('deliverable_deleted', {
        ...data,
        deletedBy: userId,
        timestamp: new Date()
      });
    });

    // Sprint events
    socket.on('sprint_created', (data) => {
      console.log('Sprint created via WebSocket:', { 
        userId, 
        email,
        sprintId: data.id 
      });
      
      socket.broadcast.emit('sprint_created', {
        ...data,
        createdBy: userId,
        timestamp: new Date()
      });
    });

    socket.on('sprint_updated', (data) => {
      console.log('Sprint updated via WebSocket:', { 
        userId, 
        email,
        sprintId: data.id 
      });
      
      this.io.emit('sprint_updated', {
        ...data,
        updatedBy: userId,
        timestamp: new Date()
      });
    });

    // Notification events
    socket.on('notification_sent', (data) => {
      console.log('Notification sent via WebSocket:', { 
        userId, 
        email,
        notificationId: data.id 
      });
      
      // Send to specific user if recipient is specified
      if (data.recipientId && data.recipientId !== userId) {
        this.io.to(`user:${data.recipientId}`).emit('notification_received', {
          ...data,
          timestamp: new Date()
        });
      } else {
        // Broadcast to appropriate role or all users
        const target = data.role ? `role:${data.role}` : 'global';
        socket.to(target).emit('notification_received', {
          ...data,
          timestamp: new Date()
        });
      }
    });

    // Presence events
    socket.on('user_activity', (data) => {
      const userData = this.connectedUsers.get(userId);
      if (userData) {
        userData.lastActivity = new Date();
        this.connectedUsers.set(userId, userData);
      }
      
      socket.to('global').emit('user_activity_update', {
        userId,
        email,
        activity: data.activity,
        timestamp: new Date()
      });
    });

    // Error handling
    socket.on('error', (error) => {
      console.error('Socket error:', { 
        userId, 
        email,
        error: error.message 
      });
    });

    // Work progress events
    socket.on('deliverable_progress_update', (data) => {
      console.log('Deliverable progress updated via WebSocket:', { 
        userId, 
        email,
        deliverableId: data.deliverable?.id 
      });
      
      // Broadcast to all users with role-based filtering
      this._broadcastWorkProgress('deliverable_progress_updated', data, userId);
    });

    socket.on('sprint_progress_update', (data) => {
      console.log('Sprint progress updated via WebSocket:', { 
        userId, 
        email,
        sprintId: data.sprint?.id 
      });
      
      // Broadcast to all users with role-based filtering
      this._broadcastWorkProgress('sprint_progress_updated', data, userId);
    });

    socket.on('work_assignment', (data) => {
      console.log('Work assigned via WebSocket:', { 
        userId, 
        email,
        assigneeId: data.assigneeId 
      });
      
      // Broadcast to target roles or specific user
      this._broadcastWorkAssignment(data, userId);
    });

    socket.on('work_completion', (data) => {
      console.log('Work completed via WebSocket:', { 
        userId, 
        email,
        workItem: data.workItem 
      });
      
      // Broadcast to target roles
      this._broadcastWorkCompletion(data, userId);
    });

    socket.on('role_sync_update', (data) => {
      console.log('Role sync update via WebSocket:', { 
        userId, 
        email,
        syncType: data.type 
      });
      
      // Broadcast to target roles
      this._broadcastRoleSync(data, userId);
    });
  }

  // Utility methods
  broadcastToRole(role, event, data) {
    this.io.to(`role:${role}`).emit(event, {
      ...data,
      timestamp: new Date()
    });
  }

  sendToUser(userId, event, data) {
    this.io.to(`user:${userId}`).emit(event, {
      ...data,
      timestamp: new Date()
    });
  }

  broadcastToAll(event, data) {
    this.io.emit(event, {
      ...data,
      timestamp: new Date()
    });
  }

  getConnectedUsers() {
    return Array.from(this.connectedUsers.values());
  }

  getUserCount() {
    return this.connectedUsers.size;
  }

  getUsersByRole(role) {
    return this.getConnectedUsers().filter(user => user.userRole === role);
  }

  // Work progress broadcasting methods
  _broadcastWorkProgress(event, data, userId) {
    const targetRoles = data.targetRoles || [];
    const broadcastData = {
      ...data,
      updatedBy: userId,
      timestamp: new Date()
    };

    if (targetRoles.length === 0) {
      // Broadcast to all users
      this.io.emit(event, broadcastData);
    } else {
      // Broadcast to specific roles
      targetRoles.forEach(role => {
        this.io.to(`role:${role}`).emit(event, broadcastData);
      });
    }
  }

  _broadcastWorkAssignment(data, userId) {
    const targetRoles = data.targetRoles || [];
    const assigneeId = data.assigneeId;
    const broadcastData = {
      ...data,
      assignedBy: userId,
      timestamp: new Date()
    };

    // Send to assignee if specified
    if (assigneeId) {
      this.io.to(`user:${assigneeId}`).emit('work_assigned', broadcastData);
    }

    // Broadcast to target roles
    if (targetRoles.length > 0) {
      targetRoles.forEach(role => {
        this.io.to(`role:${role}`).emit('work_assigned', broadcastData);
      });
    } else {
      // Default broadcast to all users
      this.io.emit('work_assigned', broadcastData);
    }
  }

  _broadcastWorkCompletion(data, userId) {
    const targetRoles = data.targetRoles || [];
    const broadcastData = {
      ...data,
      completedBy: userId,
      timestamp: new Date()
    };

    if (targetRoles.length === 0) {
      // Broadcast to all users
      this.io.emit('work_completed', broadcastData);
    } else {
      // Broadcast to specific roles
      targetRoles.forEach(role => {
        this.io.to(`role:${role}`).emit('work_completed', broadcastData);
      });
    }
  }

  _broadcastRoleSync(data, userId) {
    const targetRoles = data.targetRoles || [];
    const broadcastData = {
      ...data,
      syncBy: userId,
      timestamp: new Date()
    };

    if (targetRoles.length === 0) {
      // Broadcast to all users
      this.io.emit('role_sync_update', broadcastData);
    } else {
      // Broadcast to specific roles
      targetRoles.forEach(role => {
        this.io.to(`role:${role}`).emit('role_sync_update', broadcastData);
      });
    }
  }
}

module.exports = new SocketService();