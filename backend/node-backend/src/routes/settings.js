const express = require('express');
const router = express.Router();
const { UserSettings } = require('../models');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route GET /api/settings/me
 * @desc Get current user's settings
 * @access Private
 */
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.id;
    
    const settings = await UserSettings.findOne({ where: { user_id } });
    
    if (!settings) {
      // Return default settings if user doesn't have any saved settings
      return res.json({
        user_id,
        dark_mode: false,
        notifications_enabled: true,
        language: "English",
        sync_on_mobile_data: false,
        auto_backup: false,
        share_analytics: false,
        allow_notifications: true,
        created_at: new Date(),
        updated_at: null
      });
    }
    
    res.json(settings);
  } catch (error) {
    console.error('Error fetching user settings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/settings/me
 * @desc Create new user settings for current user
 * @access Private
 */
router.post('/me', authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.id;
    const settingsData = req.body;
    
    // Check if settings already exist for this user
    const existingSettings = await UserSettings.findOne({ where: { user_id } });
    
    if (existingSettings) {
      return res.status(400).json({ 
        error: 'Settings already exist',
        message: 'Settings already exist for this user'
      });
    }
    
    const settings = await UserSettings.create({
      user_id,
      ...settingsData
    });
    
    res.status(201).json(settings);
  } catch (error) {
    console.error('Error creating user settings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/settings/me
 * @desc Update current user's settings
 * @access Private
 */
router.put('/me', authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.id;
    const updateData = req.body;
    
    const settings = await UserSettings.findOne({ where: { user_id } });
    
    if (!settings) {
      // Create new settings if they don't exist
      const newSettings = await UserSettings.create({
        user_id,
        ...updateData
      });
      return res.json(newSettings);
    }
    
    // Update existing settings
    await settings.update(updateData);
    
    res.json(settings);
  } catch (error) {
    console.error('Error updating user settings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route DELETE /api/settings/me
 * @desc Delete current user's settings
 * @access Private
 */
router.delete('/me', authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.id;
    
    const settings = await UserSettings.findOne({ where: { user_id } });
    
    if (!settings) {
      return res.status(404).json({ error: 'Settings not found' });
    }
    
    await settings.destroy();
    
    res.json({ message: 'Settings deleted successfully' });
  } catch (error) {
    console.error('Error deleting user settings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/settings/:user_id
 * @desc Get user settings by user ID (admin only)
 * @access Private
 */
router.get('/:user_id', authenticateToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    
    const settings = await UserSettings.findOne({ where: { user_id } });
    
    if (!settings) {
      // Return default settings if user doesn't have any saved settings
      return res.json({
        user_id,
        dark_mode: false,
        notifications_enabled: true,
        language: "English",
        sync_on_mobile_data: false,
        auto_backup: false,
        share_analytics: false,
        allow_notifications: true,
        created_at: new Date(),
        updated_at: null
      });
    }
    
    res.json(settings);
  } catch (error) {
    console.error('Error fetching user settings by ID:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;