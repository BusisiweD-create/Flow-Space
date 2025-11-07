"use strict";

const { loggingService, LogLevel, LogCategory } = require('./loggingService');

class NotificationService {
  constructor() {
    this.notifications = new Map(); // user_id -> array of notifications
    loggingService.log(LogLevel.INFO, LogCategory.SYSTEM, 'Notification service initialized');
  }

  /**
   * Send a notification to a user
   * @param {string} userId - The user ID to send the notification to
   * @param {Object} notification - The notification object
   * @param {string} notification.type - The notification type (e.g., 'message', 'mention', 'system')
   * @param {string} notification.title - The notification title
   * @param {string} notification.message - The notification message
   * @param {Object} notification.data - Additional data for the notification
   * @param {boolean} notification.read - Whether the notification has been read
   * @returns {Object} The created notification
   */
  sendNotification(userId, notification) {
    const notificationData = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 5),
      timestamp: new Date(),
      read: false,
      ...notification
    };

    if (!this.notifications.has(userId)) {
      this.notifications.set(userId, []);
    }

    const userNotifications = this.notifications.get(userId);
    userNotifications.push(notificationData);

    // Keep only the last 100 notifications per user
    if (userNotifications.length > 100) {
      userNotifications.splice(0, userNotifications.length - 100);
    }

    loggingService.log(LogLevel.INFO, LogCategory.SYSTEM, 
      `Notification sent to user ${userId}: ${notification.title}`,
      null,
      { userId, notification: notificationData }
    );

    return notificationData;
  }

  /**
   * Get all notifications for a user
   * @param {string} userId - The user ID
   * @param {boolean} unreadOnly - Whether to return only unread notifications
   * @returns {Array} Array of notifications
   */
  getNotifications(userId, unreadOnly = false) {
    const userNotifications = this.notifications.get(userId) || [];
    
    if (unreadOnly) {
      return userNotifications.filter(notification => !notification.read);
    }
    
    return userNotifications;
  }

  /**
   * Mark a notification as read
   * @param {string} userId - The user ID
   * @param {string} notificationId - The notification ID
   * @returns {boolean} True if the notification was found and marked as read
   */
  markAsRead(userId, notificationId) {
    const userNotifications = this.notifications.get(userId);
    
    if (!userNotifications) {
      return false;
    }

    const notification = userNotifications.find(n => n.id === notificationId);
    
    if (notification) {
      notification.read = true;
      loggingService.log(LogLevel.INFO, LogCategory.SYSTEM, 
        `Notification ${notificationId} marked as read for user ${userId}`,
        null,
        { userId, notificationId }
      );
      return true;
    }

    return false;
  }

  /**
   * Mark all notifications as read for a user
   * @param {string} userId - The user ID
   * @returns {number} Number of notifications marked as read
   */
  markAllAsRead(userId) {
    const userNotifications = this.notifications.get(userId);
    
    if (!userNotifications) {
      return 0;
    }

    const unreadNotifications = userNotifications.filter(n => !n.read);
    
    unreadNotifications.forEach(notification => {
      notification.read = true;
    });

    loggingService.log(LogLevel.INFO, LogCategory.SYSTEM, 
      `All notifications marked as read for user ${userId}`,
      null,
      { userId, markedCount: unreadNotifications.length }
    );

    return unreadNotifications.length;
  }

  /**
   * Delete a notification
   * @param {string} userId - The user ID
   * @param {string} notificationId - The notification ID
   * @returns {boolean} True if the notification was found and deleted
   */
  deleteNotification(userId, notificationId) {
    const userNotifications = this.notifications.get(userId);
    
    if (!userNotifications) {
      return false;
    }

    const initialLength = userNotifications.length;
    const filteredNotifications = userNotifications.filter(n => n.id !== notificationId);
    
    if (filteredNotifications.length < initialLength) {
      this.notifications.set(userId, filteredNotifications);
      loggingService.log(LogLevel.INFO, LogCategory.SYSTEM, 
        `Notification ${notificationId} deleted for user ${userId}`,
        null,
        { userId, notificationId }
      );
      return true;
    }

    return false;
  }

  /**
   * Clear all notifications for a user
   * @param {string} userId - The user ID
   * @returns {number} Number of notifications cleared
   */
  clearNotifications(userId) {
    const userNotifications = this.notifications.get(userId);
    
    if (!userNotifications) {
      return 0;
    }

    const count = userNotifications.length;
    this.notifications.set(userId, []);

    loggingService.log(LogLevel.INFO, LogCategory.SYSTEM, 
      `All notifications cleared for user ${userId}`,
      null,
      { userId, clearedCount: count }
    );

    return count;
  }

  /**
   * Get notification statistics for a user
   * @param {string} userId - The user ID
   * @returns {Object} Notification statistics
   */
  getNotificationStats(userId) {
    const userNotifications = this.notifications.get(userId) || [];
    
    const total = userNotifications.length;
    const unread = userNotifications.filter(n => !n.read).length;
    const read = total - unread;

    return {
      total,
      unread,
      read,
      lastNotification: userNotifications.length > 0 ? userNotifications[userNotifications.length - 1] : null
    };
  }
}

// Global notification service instance
const notificationService = new NotificationService();

module.exports = {
  NotificationService,
  notificationService
};