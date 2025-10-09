"use strict";

const express = require('express');
const multer = require('multer');
const fileUploadService = require('../services/fileUploadService');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = [
            'image/jpeg',
            'image/png', 
            'image/gif',
            'image/webp',
            'application/pdf'
        ];
        
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('File type not allowed'), false);
        }
    }
});

// Upload single file
router.post('/upload', authenticateToken, upload.single('file'), async (req, res) => {
    try {
        const { prefix = '' } = req.body;
        
        if (!req.file) {
            return res.status(400).json({ 
                error: 'No file provided' 
            });
        }
        
        const uploadResult = await fileUploadService.uploadFile(req.file, prefix);
        res.status(200).json(uploadResult);
        
    } catch (error) {
        console.error('File upload error:', error);
        res.status(500).json({ 
            error: 'File upload failed', 
            details: error.message 
        });
    }
});

// Upload multiple files
router.post('/upload-multiple', authenticateToken, upload.array('files'), async (req, res) => {
    try {
        const { prefix = '' } = req.body;
        
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ 
                error: 'No files provided' 
            });
        }
        
        const results = [];
        
        for (const file of req.files) {
            try {
                const uploadResult = await fileUploadService.uploadFile(file, prefix);
                results.push({
                    ...uploadResult,
                    success: true
                });
            } catch (error) {
                results.push({
                    filename: file.originalname,
                    error: error.message,
                    success: false
                });
            }
        }
        
        res.status(200).json(results);
        
    } catch (error) {
        console.error('Multiple file upload error:', error);
        res.status(500).json({ 
            error: 'Multiple file upload failed', 
            details: error.message 
        });
    }
});

// Get presigned URL for file access
router.get('/presigned-url/:filename', authenticateToken, async (req, res) => {
    try {
        const { filename } = req.params;
        const { expires_in = 3600 } = req.query;
        
        const expiresIn = parseInt(expires_in);
        
        const presignedUrl = fileUploadService.getPresignedUrl(filename, expiresIn);
        
        if (!presignedUrl) {
            return res.status(404).json({ 
                error: 'File not found or presigned URL generation failed' 
            });
        }
        
        const expiresAt = new Date(Date.now() + expiresIn * 1000);
        
        res.status(200).json({
            filename,
            presigned_url: presignedUrl,
            expires_at: expiresAt.toISOString()
        });
        
    } catch (error) {
        console.error('Presigned URL error:', error);
        res.status(500).json({ 
            error: 'Failed to generate presigned URL', 
            details: error.message 
        });
    }
});

// Delete file
router.delete('/:filename', authenticateToken, async (req, res) => {
    try {
        const { filename } = req.params;
        
        const success = await fileUploadService.deleteFile(filename);
        
        if (!success) {
            return res.status(404).json({ 
                error: 'File not found or deletion failed' 
            });
        }
        
        res.status(200).json({ 
            message: 'File deleted successfully', 
            filename 
        });
        
    } catch (error) {
        console.error('File deletion error:', error);
        res.status(500).json({ 
            error: 'File deletion failed', 
            details: error.message 
        });
    }
});

module.exports = router;