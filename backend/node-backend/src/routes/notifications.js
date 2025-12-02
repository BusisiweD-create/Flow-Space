const express = require('express');
const router = express.Router();
const { Notification, User } = require('../models');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route POST /api/notifications
 * @desc Create a new notification
 * @access Private
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const notificationData = req.body;
    
    // Ensure the recipient exists
    const recipient = await User.findByPk(notificationData.recipient_id);
    if (!recipient) {
      return res.status(404).json({ error: 'Recipient not found' });
    }
    
    // Set sender_id if not provided (e.g., system notification) or if it's the current user
    if (notificationData.sender_id === undefined || notificationData.sender_id === null) {
      notificationData.sender_id = req.user.id;
    } else if (notificationData.sender_id !== req.user.id) {
      return res.status(403).json({
        error: 'Not authorized',
        message: 'Not authorized to send notifications on behalf of another user'
      });
    }
    
    const notification = await Notification.create(notificationData);
    
    res.status(201).json(notification);
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/notifications/me
 * @desc Get notifications for current user
 * @access Private
 */
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const { skip = 0, limit = 100, unread_only } = req.query;

    const uid = req.user && req.user.id;
    if (!uid || !/^[0-9a-fA-F-]{36}$/.test(String(uid))) {
      return res.json([]);
    }

    const where = { recipient_id: uid };
    if (String(unread_only || '').toLowerCase() === 'true') {
      where.is_read = false;
    }

    const notifications = await Notification.findAll({
      where,
      offset: parseInt(skip),
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });
    
    res.json(notifications);
  } catch (error) {
    console.error('Error fetching user notifications:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/notifications/:id
 * @desc Get a specific notification
 * @access Private
 */
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const notification = await Notification.findByPk(id);
    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    
    if (notification.recipient_id !== req.user.id && notification.sender_id !== req.user.id) {
      return res.status(403).json({
        error: 'Not authorized',
        message: 'Not authorized to view this notification'
      });
    }
    
    res.json(notification);
  } catch (error) {
    console.error('Error fetching notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/notifications/:id/read
 * @desc Mark a notification as read
 * @access Private
 */
router.put('/:id/read', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const notification = await Notification.findByPk(id);
    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    
    if (notification.recipient_id !== req.user.id) {
      return res.status(403).json({
        error: 'Not authorized',
        message: 'Not authorized to mark this notification as read'
      });
    }
    
    await notification.update({ is_read: true });
    
    res.json(notification);
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/read-all', authenticateToken, async (req, res) => {
  try {
    const uid = req.user && req.user.id;
    if (!uid || !/^[0-9a-fA-F-]{36}$/.test(String(uid))) {
      return res.json({ success: true, data: { markedCount: 0 } });
    }

    const [affectedCount] = await Notification.update(
      { is_read: true },
      { where: { recipient_id: uid, is_read: false } }
    );
    res.json({ success: true, data: { markedCount: affectedCount } });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/count', authenticateToken, async (req, res) => {
  try {
    const uid = req.user && req.user.id;
    if (!uid || !/^[0-9a-fA-F-]{36}$/.test(String(uid))) {
      return res.json({ success: true, data: { unreadCount: 0 } });
    }

    const unreadCount = await Notification.count({
      where: { recipient_id: uid, is_read: false }
    });
    res.json({ success: true, data: { unreadCount } });
  } catch (error) {
    console.error('Error fetching unread notification count:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route DELETE /api/notifications/:id
 * @desc Delete a notification
 * @access Private
 */
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const notification = await Notification.findByPk(id);
    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    
    if (notification.recipient_id !== req.user.id) {
      return res.status(403).json({
        error: 'Not authorized',
        message: 'Not authorized to delete this notification'
      });
    }
    
    await notification.destroy();
    
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
