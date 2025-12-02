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
    
    async uploadFile(file, prefix = '', metaOverrides = {}) {
        try {
            await this.ensureStorageDirectory();
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
            const metadata = {
                originalName: file.originalname,
                uploadDate: new Date().toISOString(),
                title: typeof metaOverrides.title === 'string' && metaOverrides.title.trim() !== '' ? metaOverrides.title.trim() : file.originalname,
                description: typeof metaOverrides.description === 'string' ? metaOverrides.description : '',
                tags: Array.isArray(metaOverrides.tags) ? metaOverrides.tags : (typeof metaOverrides.tags === 'string' && metaOverrides.tags.trim() !== '' ? metaOverrides.tags.split(',').map(s=>s.trim()) : []),
                uploadedBy: typeof metaOverrides.uploadedBy === 'string' ? metaOverrides.uploadedBy : undefined
            };
            try {
                await fs.writeFile(`${storagePath}.meta.json`, JSON.stringify(metadata));
            } catch (error) {}
            
            return {
                filename: uniqueFilename,
                originalName: file.originalname,
                title: metadata.title,
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
            // Try direct path first
            const directPath = path.join(this.storageBasePath, filename);
            const candidates = [directPath];
            // Also check one-level subdirectories for the file
            try {
                const entries = await fs.readdir(this.storageBasePath, { withFileTypes: true });
                for (const entry of entries) {
                    if (entry.isDirectory()) {
                        candidates.push(path.join(this.storageBasePath, entry.name, filename));
                    }
                }
            } catch (_) {}

            for (const p of candidates) {
                try {
                    await fs.access(p);
                    await fs.unlink(p);
                    // Delete sidecar metadata if present
                    try { await fs.unlink(`${p}.meta.json`); } catch (_) {}
                    return true;
                } catch (error) {
                    if (error.code === 'ENOENT') {
                        continue;
                    }
                }
            }
            return false;
        } catch (error) {
            console.error('File deletion failed:', error);
            return false;
        }
    }

    async listFiles(prefix = '') {
        try {
            const directoryPath = prefix ? path.join(this.storageBasePath, prefix) : this.storageBasePath;
            
            // Check if directory exists
            try {
                await fs.access(directoryPath);
            } catch (error) {
                if (error.code === 'ENOENT') {
                    return []; // Directory doesn't exist, return empty list
                }
                throw error;
            }
            
            const files = await fs.readdir(directoryPath);
            const fileDetails = [];
            
            for (const file of files) {
                try {
                    const filePath = path.join(directoryPath, file);
                    const stats = await fs.stat(filePath);
                    
                    if (stats.isFile()) {
                        let originalName = file;
                        let title = undefined;
                        let description = '';
                        let tags = [];
                        let uploadDate = stats.mtime;
                        try {
                            const metaRaw = await fs.readFile(`${filePath}.meta.json`, 'utf8');
                            const meta = JSON.parse(metaRaw);
                            if (meta && meta.originalName) originalName = meta.originalName;
                            if (meta && meta.title) title = meta.title;
                            if (meta && meta.description) description = meta.description;
                            if (meta && meta.tags) tags = meta.tags;
                            if (meta && meta.uploadDate) uploadDate = new Date(meta.uploadDate);
                        } catch (_) {}
                        fileDetails.push({
                            filename: file,
                            originalName: originalName,
                            title: title,
                            description: description,
                            tags: tags,
                            size: stats.size,
                            uploadDate: uploadDate,
                            url: `${this.baseUrl}/${prefix ? prefix + '/' : ''}${file}`,
                            storageProvider: 'local'
                        });
                    }
                } catch (error) {
                    console.error(`Error getting details for file ${file}:`, error);
                    // Continue with other files
                }
            }
            
            return fileDetails;
            
        } catch (error) {
            console.error('File listing failed:', error);
            throw new Error(`File listing failed: ${error.message}`);
        }
    }
}

// Create global instance
const fileUploadService = new FileUploadService();

module.exports = fileUploadService;
