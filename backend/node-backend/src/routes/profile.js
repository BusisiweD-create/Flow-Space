const express = require('express');
const router = express.Router();
const { UserProfile, User } = require('../models');
const { authenticateToken } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for file uploads
const uploadBaseDir = path.join(__dirname, '..', 'uploads', 'profile_pictures');
try { fs.mkdirSync(uploadBaseDir, { recursive: true }); } catch (_) {}
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadBaseDir);
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
    const profileData = req.body || {};
    const bodyUserId = profileData.user_id || (req.user && req.user.id);
    if (!bodyUserId) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    // Check if profile already exists
    const existingProfile = await UserProfile.findOne({ 
      where: { user_id: bodyUserId } 
    });
    if (existingProfile) {
      return res.status(400).json({ 
        error: 'Profile already exists',
        message: 'Profile already exists for this user'
      });
    }
    
    // Resolve required fields (email, first_name, last_name)
    let email = (profileData.email || '').toString();
    let firstName = (profileData.first_name || profileData.firstName || '').toString();
    let lastName = (profileData.last_name || profileData.lastName || '').toString();

    if (!email || !firstName || !lastName) {
      try {
        const user = await User.findByPk(bodyUserId);
        if (user) {
          email = email || user.email || '';
          firstName = firstName || user.first_name || '';
          lastName = lastName || user.last_name || '';
        }
      } catch (_) {}
    }

    if (!email) {
      email = `${bodyUserId}@local.invalid`;
    }

    // Check if email is already taken by a different user
    if (email) {
      const existingEmail = await UserProfile.findOne({ where: { email } });
      if (existingEmail && existingEmail.user_id !== bodyUserId) {
        return res.status(409).json({ 
          error: 'Email already registered',
          message: 'Email already registered by another user'
        });
      }
    }

    const finalData = {
      user_id: bodyUserId,
      email,
      first_name: firstName,
      last_name: lastName,
      phone_number: profileData.phone_number || profileData.phoneNumber || null,
      profile_picture: profileData.profile_picture || profileData.profilePicture || null,
      bio: profileData.bio || '',
      job_title: profileData.job_title || profileData.jobTitle || '',
      company: profileData.company || '',
      location: profileData.location || '',
      website: profileData.website || '',
      date_of_birth: profileData.date_of_birth || profileData.dateOfBirth || null
    };

    const profile = await UserProfile.create(finalData);
    
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
    
    // Ensure profile exists; create minimal profile if missing
    let profile = await UserProfile.findOne({ where: { user_id } });
    if (!profile) {
      try {
        let email = (req.user && req.user.email) || '';
        let firstName = '';
        let lastName = '';
        try {
          const user = await User.findByPk(user_id);
          if (user) {
            email = email || user.email || '';
            firstName = user.first_name || '';
            lastName = user.last_name || '';
          }
        } catch (_) {}

        if (!email) {
          email = `${user_id}@local.invalid`;
        }

        profile = await UserProfile.create({
          user_id,
          email,
          first_name: firstName,
          last_name: lastName,
          job_title: '',
          company: '',
          bio: ''
        });
      } catch (createErr) {
        console.error('Failed to create minimal profile for upload:', createErr);
        return res.status(404).json({ error: 'Profile not found' });
      }
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
      absolute_url: `${req.protocol}://${req.get('host')}${fileUrl}`,
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
 * @route GET /api/profile/:user_id/picture
 * @desc Stream the user's current profile picture
 * @access Private
 */
router.get('/:user_id/picture', authenticateToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    const profile = await UserProfile.findOne({ where: { user_id } });
    if (!profile || !profile.profile_picture) {
      return res.status(404).json({ error: 'Profile picture not found' });
    }
    const picUrl = profile.profile_picture.toString();
    const filename = path.basename(picUrl);
    const fullPath = path.join(__dirname, '..', 'uploads', 'profile_pictures', filename);
    if (!fs.existsSync(fullPath)) {
      return res.status(404).json({ error: 'Profile picture file missing' });
    }
    const ext = path.extname(filename).toLowerCase();
    const ct = ext === '.png' ? 'image/png'
      : (ext === '.gif' ? 'image/gif'
      : (ext === '.webp' ? 'image/webp' : 'image/jpeg'));
    res.setHeader('Content-Type', ct);
    res.sendFile(fullPath);
  } catch (error) {
    console.error('Error streaming profile picture:', error);
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
