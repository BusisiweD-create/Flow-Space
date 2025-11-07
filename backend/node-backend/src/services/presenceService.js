const { loggingService, LogLevel, LogCategory } = require('./loggingService');

/**
 * Presence Service
 * Tracks user presence and online status
 */
class PresenceService {
  constructor() {
    this.onlineUsers = new Map(); // user_id -> { lastSeen, status, socketId }
    this.userSessions = new Map(); // socketId -> user_id
    loggingService.log(LogLevel.INFO, LogCategory.SYSTEM, 'Presence service initialized');
  }

  /**
   * Mark user as online
   * @param {string} userId - User ID
   * @param {string} socketId - Socket connection ID
   * @param {string} status - User status (online, away, busy)
   */
  userConnected(userId, socketId, status = 'online') {
    this.onlineUsers.set(userId, {
      lastSeen: new Date(),
      status: status,
      socketId: socketId
    });
    this.userSessions.set(socketId, userId);
    
    loggingService.log(LogLevel.INFO, LogCategory.WEBSOCKET, `User ${userId} connected with status: ${status}`, null, { userId, socketId, status });
  }

  /**
   * Mark user as offline
   * @param {string} socketId - Socket connection ID
   */
  userDisconnected(socketId) {
    const userId = this.userSessions.get(socketId);
    if (userId) {
      this.onlineUsers.delete(userId);
      this.userSessions.delete(socketId);
      loggingService.log(LogLevel.INFO, LogCategory.WEBSOCKET, `User ${userId} disconnected`, null, { userId, socketId });
    }
  }

  /**
   * Update user status
   * @param {string} userId - User ID
   * @param {string} status - New status
   */
  updateUserStatus(userId, status) {
    if (this.onlineUsers.has(userId)) {
      const userData = this.onlineUsers.get(userId);
      userData.status = status;
      userData.lastSeen = new Date();
      this.onlineUsers.set(userId, userData);
      
      loggingService.log(LogLevel.INFO, LogCategory.WEBSOCKET, `User ${userId} status updated to: ${status}`, null, { userId, status });
      return true;
    }
    return false;
  }

  /**
   * Get user presence information
   * @param {string} userId - User ID
   * @returns {Object|null} User presence data
   */
  getUserPresence(userId) {
    if (this.onlineUsers.has(userId)) {
      const userData = this.onlineUsers.get(userId);
      return {
        online: true,
        status: userData.status,
        lastSeen: userData.lastSeen
      };
    }
    return {
      online: false,
      status: 'offline',
      lastSeen: null
    };
  }

  /**
   * Get all online users
   * @returns {Array} List of online users
   */
  getOnlineUsers() {
    const onlineUsers = [];
    for (const [userId, userData] of this.onlineUsers.entries()) {
      onlineUsers.push({
        userId,
        status: userData.status,
        lastSeen: userData.lastSeen
      });
    }
    return onlineUsers;
  }

  /**
   * Get number of online users
   * @returns {number} Count of online users
   */
  getOnlineUsersCount() {
    return this.onlineUsers.size;
  }

  /**
   * Clean up stale connections (users who haven't been seen in a while)
   * @param {number} timeoutMs - Timeout in milliseconds (default: 5 minutes)
   */
  cleanupStaleConnections(timeoutMs = 5 * 60 * 1000) {
    const now = new Date();
    let cleanedCount = 0;
    
    for (const [userId, userData] of this.onlineUsers.entries()) {
      if (now - userData.lastSeen > timeoutMs) {
        this.onlineUsers.delete(userId);
        if (userData.socketId) {
          this.userSessions.delete(userData.socketId);
        }
        cleanedCount++;
        logger.info(`Cleaned up stale connection for user ${userId}`, { userId });
      }
    }
    
    if (cleanedCount > 0) {
      logger.info(`Cleaned up ${cleanedCount} stale connections`);
    }
  }
}

// Create singleton instance
const presenceService = new PresenceService();

// Clean up stale connections every minute
setInterval(() => {
  presenceService.cleanupStaleConnections();
}, 60 * 1000);

module.exports = presenceService;