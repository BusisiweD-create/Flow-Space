const express = require('express');
const router = express.Router();
const { UserProfile } = require('../models');
const { authenticateToken } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/profile_pictures/')
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, req.params.user_id + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: function (req, file, cb) {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

/**
 * @route GET /api/profile
 * @desc Get all user profiles
 * @access Private
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    
    const profiles = await UserProfile.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit)
    });
    
    res.json(profiles);
  } catch (error) {
    console.error('Error fetching profiles:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/profile/:user_id
 * @desc Get user profile by user ID
 * @access Private
 */
router.get('/:user_id', authenticateToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    
    const profile = await UserProfile.findOne({ where: { user_id } });
    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    res.json(profile);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/profile
 * @desc Create a new user profile
 * @access Private
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const profileData = req.body;
    
    // Check if profile already exists
    const existingProfile = await UserProfile.findOne({ 
      where: { user_id: profileData.user_id } 
    });
    if (existingProfile) {
      return res.status(400).json({ 
        error: 'Profile already exists',
        message: 'Profile already exists for this user'
      });
    }
    
    // Check if email is already taken
    const existingEmail = await UserProfile.findOne({ 
      where: { email: profileData.email } 
    });
    if (existingEmail) {
      return res.status(400).json({ 
        error: 'Email already registered',
        message: 'Email already registered'
      });
    }
    
    const profile = await UserProfile.create(profileData);
    
    res.status(201).json(profile);
  } catch (error) {
    console.error('Error creating profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/profile/:user_id
 * @desc Update user profile
 * @access Private
 */
router.put('/:user_id', authenticateToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    const updateData = req.body;
    
    const profile = await UserProfile.findOne({ where: { user_id } });
    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    await profile.update(updateData);
    
    res.json(profile);
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route DELETE /api/profile/:user_id
 * @desc Delete user profile
 * @access Private
 */
router.delete('/:user_id', authenticateToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    
    const profile = await UserProfile.findOne({ where: { user_id } });
    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    await profile.destroy();
    
    res.json({ message: 'Profile deleted successfully' });
  } catch (error) {
    console.error('Error deleting profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/profile/:user_id/upload-picture
 * @desc Upload profile picture for user
 * @access Private
 */
router.post('/:user_id/upload-picture', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Check if user exists
    const profile = await UserProfile.findOne({ where: { user_id } });
    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    
    // Construct the file URL (in production, this would be a CDN URL)
    const fileUrl = `/uploads/profile_pictures/${req.file.filename}`;
    
    // Update profile with picture URL
    await profile.update({ profile_picture: fileUrl });
    
    res.json({
      url: fileUrl,
      filename: req.file.filename,
      originalname: req.file.originalname,
      size: req.file.size
    });
    
  } catch (error) {
    console.error('Error uploading profile picture:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/profile/email/:email
 * @desc Get user profile by email
 * @access Private
 */
router.get('/email/:email', authenticateToken, async (req, res) => {
  try {
    const { email } = req.params;
    
    const profile = await UserProfile.findOne({ where: { email } });
    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    res.json(profile);
  } catch (error) {
    console.error('Error fetching profile by email:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;