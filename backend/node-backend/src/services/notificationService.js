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

  /**
   * Send work progress notification
   * @param {string} userId - The user ID to notify
   * @param {Object} workData - Work progress data
   * @param {string} workData.type - Work type ('deliverable', 'sprint', 'task')
   * @param {string} workData.id - Work item ID
   * @param {string} workData.title - Work item title
   * @param {string} workData.status - Current status
   * @param {number} workData.progress - Progress percentage (0-100)
   * @param {string} workData.updatedBy - User who made the update
   * @returns {Object} The created notification
   */
  sendWorkProgressNotification(userId, workData) {
    const { type, id, title, status, progress, updatedBy } = workData;
    
    let notificationType = 'work_progress';
    let notificationTitle = '';
    let notificationMessage = '';

    switch (type) {
      case 'deliverable':
        notificationTitle = 'Deliverable Progress Update';
        notificationMessage = `${title} is now ${progress}% complete. Status: ${status}`;
        break;
      case 'sprint':
        notificationTitle = 'Sprint Progress Update';
        notificationMessage = `${title} is now ${progress}% complete. Status: ${status}`;
        break;
      case 'task':
        notificationTitle = 'Task Progress Update';
        notificationMessage = `${title} is now ${progress}% complete. Status: ${status}`;
        break;
      default:
        notificationTitle = 'Work Progress Update';
        notificationMessage = `${title} is now ${progress}% complete. Status: ${status}`;
    }

    if (updatedBy) {
      notificationMessage += ` (Updated by ${updatedBy})`;
    }

    return this.sendNotification(userId, {
      type: notificationType,
      title: notificationTitle,
      message: notificationMessage,
      data: {
        workType: type,
        workId: id,
        progress,
        status,
        updatedBy,
        timestamp: new Date()
      }
    });
  }

  /**
   * Send work assignment notification
   * @param {string} userId - The user ID to notify
   * @param {Object} assignmentData - Assignment data
   * @param {string} assignmentData.type - Assignment type ('deliverable', 'sprint', 'task')
   * @param {string} assignmentData.id - Work item ID
   * @param {string} assignmentData.title - Work item title
   * @param {string} assignmentData.assignedBy - User who made the assignment
   * @param {string} assignmentData.dueDate - Due date (optional)
   * @returns {Object} The created notification
   */
  sendWorkAssignmentNotification(userId, assignmentData) {
    const { type, id, title, assignedBy, dueDate } = assignmentData;
    
    let notificationTitle = '';
    let notificationMessage = '';

    switch (type) {
      case 'deliverable':
        notificationTitle = 'New Deliverable Assignment';
        notificationMessage = `You have been assigned to deliverable: ${title}`;
        break;
      case 'sprint':
        notificationTitle = 'New Sprint Assignment';
        notificationMessage = `You have been assigned to sprint: ${title}`;
        break;
      case 'task':
        notificationTitle = 'New Task Assignment';
        notificationMessage = `You have been assigned to task: ${title}`;
        break;
      default:
        notificationTitle = 'New Work Assignment';
        notificationMessage = `You have been assigned to: ${title}`;
    }

    if (assignedBy) {
      notificationMessage += ` (Assigned by ${assignedBy})`;
    }

    if (dueDate) {
      notificationMessage += ` | Due: ${dueDate}`;
    }

    return this.sendNotification(userId, {
      type: 'work_assignment',
      title: notificationTitle,
      message: notificationMessage,
      data: {
        workType: type,
        workId: id,
        assignedBy,
        dueDate,
        timestamp: new Date()
      }
    });
  }

  /**
   * Send work completion notification
   * @param {string} userId - The user ID to notify
   * @param {Object} completionData - Completion data
   * @param {string} completionData.type - Work type ('deliverable', 'sprint', 'task')
   * @param {string} completionData.id - Work item ID
   * @param {string} completionData.title - Work item title
   * @param {string} completionData.completedBy - User who completed the work
   * @returns {Object} The created notification
   */
  sendWorkCompletionNotification(userId, completionData) {
    const { type, id, title, completedBy } = completionData;
    
    let notificationTitle = '';
    let notificationMessage = '';

    switch (type) {
      case 'deliverable':
        notificationTitle = 'Deliverable Completed';
        notificationMessage = `${title} has been completed`;
        break;
      case 'sprint':
        notificationTitle = 'Sprint Completed';
        notificationMessage = `${title} has been completed`;
        break;
      case 'task':
        notificationTitle = 'Task Completed';
        notificationMessage = `${title} has been completed`;
        break;
      default:
        notificationTitle = 'Work Completed';
        notificationMessage = `${title} has been completed`;
    }

    if (completedBy) {
      notificationMessage += ` (Completed by ${completedBy})`;
    }

    return this.sendNotification(userId, {
      type: 'work_completion',
      title: notificationTitle,
      message: notificationMessage,
      data: {
        workType: type,
        workId: id,
        completedBy,
        timestamp: new Date()
      }
    });
  }

  /**
   * Send role synchronization notification
   * @param {string} userId - The user ID to notify
   * @param {Object} syncData - Synchronization data
   * @param {string} syncData.type - Sync type ('role_update', 'permission_change', 'team_change')
   * @param {string} syncData.description - Sync description
   * @param {string} syncData.initiatedBy - User who initiated the sync
   * @returns {Object} The created notification
   */
  sendRoleSyncNotification(userId, syncData) {
    const { type, description, initiatedBy } = syncData;
    
    let notificationTitle = '';
    let notificationMessage = description;

    switch (type) {
      case 'role_update':
        notificationTitle = 'Role Update';
        break;
      case 'permission_change':
        notificationTitle = 'Permission Change';
        break;
      case 'team_change':
        notificationTitle = 'Team Change';
        break;
      default:
        notificationTitle = 'System Update';
    }

    if (initiatedBy) {
      notificationMessage += ` (Initiated by ${initiatedBy})`;
    }

    return this.sendNotification(userId, {
      type: 'role_sync',
      title: notificationTitle,
      message: notificationMessage,
      data: {
        syncType: type,
        initiatedBy,
        timestamp: new Date()
      }
    });
  }
}

// Global notification service instance
const notificationService = new NotificationService();

module.exports = {
  NotificationService,
  notificationService
};