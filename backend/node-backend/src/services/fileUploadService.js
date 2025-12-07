"use strict";

const fs = require('fs').promises;
const path = require('path');
const { v4: uuidv4 } = require('uuid');

class FileUploadService {
    constructor() {
        this.storageBasePath = process.env.FILE_STORAGE_PATH || 'uploads';
        this.baseUrl = process.env.FILE_BASE_URL || '/uploads';
        
        // Create storage directory if it doesn't exist
        this.ensureStorageDirectory();
    }
    
    async ensureStorageDirectory() {
        try {
            await fs.mkdir(this.storageBasePath, { recursive: true });
        } catch (error) {
            console.error('Failed to create storage directory:', error);
        }
    }
    
    async uploadFile(file, prefix = '') {
        try {
            // Generate unique filename
            const fileExtension = path.extname(file.originalname) || '.bin';
            const uniqueFilename = `${uuidv4().replace(/-/g, '')}${fileExtension}`;
            
            let storagePath;
            let urlPath;
            
            if (prefix) {
                const fullPrefix = path.join(this.storageBasePath, prefix);
                await fs.mkdir(fullPrefix, { recursive: true });
                storagePath = path.join(fullPrefix, uniqueFilename);
                urlPath = `${this.baseUrl}/${prefix}/${uniqueFilename}`;
            } else {
                storagePath = path.join(this.storageBasePath, uniqueFilename);
                urlPath = `${this.baseUrl}/${uniqueFilename}`;
            }
            
            // Write file to storage
            await fs.writeFile(storagePath, file.buffer);
            
            return {
                filename: uniqueFilename,
                originalName: file.originalname,
                url: urlPath,
                size: file.size,
                storageProvider: 'local'
            };
            
        } catch (error) {
            console.error('File upload failed:', error);
            throw new Error(`File upload failed: ${error.message}`);
        }
    }
    
    getPresignedUrl(filename, expiresIn = 3600) {
        // For local storage, we just return the direct URL
        // In production, this would generate a signed URL for cloud storage
        return `${this.baseUrl}/${filename}`;
    }
    
    async deleteFile(filename) {
        try {
            const filePath = path.join(this.storageBasePath, filename);
            
            try {
                await fs.access(filePath);
                await fs.unlink(filePath);
                return true;
            } catch (error) {
                if (error.code === 'ENOENT') {
                    return false; // File doesn't exist
                }
                throw error;
            }
            
        } catch (error) {
            console.error('File deletion failed:', error);
            return false;
        }
    }
}

// Create global instance
const fileUploadService = new FileUploadService();

module.exports = fileUploadService;