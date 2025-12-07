"use strict";

const express = require('express');
const { Sequelize, Op } = require('sequelize');
const fs = require('fs');
const path = require('path');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { User, Project, Sprint, Deliverable, AuditLog } = require('../models');
const analyticsService = require('../services/analyticsService');
const { loggingService } = require('../services/loggingService');

const router = express.Router();

// System settings storage (in-memory for now, could be moved to database)
let systemSettings = {
  maintenanceMode: false,
  maintenanceMessage: "System is under maintenance. Please try again later.",
  allowNewRegistrations: true,
  maxFileUploadSize: 50, // MB
  sessionTimeout: 24, // hours
  backupRetentionDays: 30,
  systemNotifications: true,
  performanceMonitoring: true,
  auditLogRetentionDays: 90
};

// Get system settings (admin only)
router.get('/settings', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    res.status(200).json({
      status: 'success',
      settings: systemSettings,
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('System settings error:', error);
    res.status(500).json({
      error: 'Failed to get system settings',
      details: error.message
    });
  }
});

// Update system settings (admin only)
router.put('/settings', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    const updates = req.body;
    
    // Validate updates
    const validSettings = Object.keys(systemSettings);
    const invalidKeys = Object.keys(updates).filter(key => !validSettings.includes(key));
    
    if (invalidKeys.length > 0) {
      return res.status(400).json({
        error: 'Invalid settings',
        details: `Invalid setting keys: ${invalidKeys.join(', ')}`
      });
    }
    
    // Update settings
    systemSettings = { ...systemSettings, ...updates };
    
    // Log the change
    await AuditLog.logChange({
      userId: req.user.id,
      action: 'system_settings_update',
      entityType: 'system',
      entityId: 'global',
      oldValues: {},
      newValues: updates,
      description: `System settings updated by ${req.user.email}`
    });
    
    res.status(200).json({
      status: 'success',
      message: 'System settings updated successfully',
      settings: systemSettings,
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('System settings update error:', error);
    res.status(500).json({
      error: 'Failed to update system settings',
      details: error.message
    });
  }
});

// Create system backup (admin only)
router.post('/backup', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = path.join(__dirname, '..', '..', 'backups');
    const backupFile = path.join(backupDir, `backup-${timestamp}.sql`);
    const metadataFile = path.join(backupDir, `backup-${timestamp}.json`);
    
    // Create backups directory if it doesn't exist
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }
    
    // Get database configuration from environment
    const dbConfig = {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres'
    };
    
    // Create backup metadata
    const backupData = {
      timestamp: new Date().toISOString(),
      createdBy: req.user.email,
      userId: req.user.id,
      database: dbConfig.database,
      tables: {
        users: await User.count(),
        projects: await Project.count(),
        sprints: await Sprint.count(),
        deliverables: await Deliverable.count(),
        auditLogs: await AuditLog.count()
      },
      settings: systemSettings,
      dbConfig: {
        host: dbConfig.host,
        port: dbConfig.port,
        database: dbConfig.database,
        user: dbConfig.user
      }
    };
    
    // Use pg_dump for PostgreSQL backup
    const { exec } = require('child_process');
    const pgDumpCommand = `pg_dump -h ${dbConfig.host} -p ${dbConfig.port} -U ${dbConfig.user} -d ${dbConfig.database} -F c -f "${backupFile}"`;
    
    // Set PGPASSWORD environment variable for authentication
    const env = { ...process.env, PGPASSWORD: dbConfig.password };
    
    exec(pgDumpCommand, { env }, async (error, stdout, stderr) => {
      if (error) {
        console.error('pg_dump error:', error);
        console.error('stderr:', stderr);
        
        // Fallback to metadata-only backup if pg_dump fails
        console.log('Falling back to metadata-only backup');
        fs.writeFileSync(metadataFile, JSON.stringify(backupData, null, 2));
        
        // Log the backup creation (metadata only)
        await AuditLog.logChange({
          userId: req.user.id,
          action: 'system_backup_created_metadata',
          entityType: 'system',
          entityId: 'backup',
          oldValues: {},
          newValues: { backupFile: metadataFile, ...backupData },
          description: `System metadata backup created (pg_dump failed) by ${req.user.email}: ${error.message}`
        });
        
        return res.status(201).json({
          status: 'partial_success',
          message: 'Metadata backup created (database backup failed)',
          backup: {
            filename: `backup-${timestamp}.json`,
            path: metadataFile,
            createdAt: new Date().toISOString(),
            createdBy: req.user.email,
            stats: backupData.tables,
            type: 'metadata_only',
            warning: 'Database backup failed, only metadata saved'
          },
          timestamp: Date.now()
        });
      }
      
      // Write metadata file for successful backup
      fs.writeFileSync(metadataFile, JSON.stringify(backupData, null, 2));
      
      // Get backup file stats
      const stats = fs.statSync(backupFile);
      
      // Log the successful backup creation
      await AuditLog.logChange({
        userId: req.user.id,
        action: 'system_backup_created',
        entityType: 'system',
        entityId: 'backup',
        oldValues: {},
        newValues: { 
          backupFile, 
          metadataFile,
          size: stats.size,
          ...backupData 
        },
        description: `System backup created successfully by ${req.user.email}`
      });
      
      res.status(201).json({
        status: 'success',
        message: 'System backup created successfully',
        backup: {
          filename: `backup-${timestamp}.sql`,
          metadataFilename: `backup-${timestamp}.json`,
          path: backupFile,
          size: stats.size,
          createdAt: new Date().toISOString(),
          createdBy: req.user.email,
          stats: backupData.tables,
          type: 'full_database'
        },
        timestamp: Date.now()
      });
    });
  } catch (error) {
    console.error('Backup creation error:', error);
    res.status(500).json({
      error: 'Failed to create system backup',
      details: error.message
    });
  }
});

// List system backups (admin only)
router.get('/backups', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    const backupDir = path.join(__dirname, '..', '..', 'backups');
    
    if (!fs.existsSync(backupDir)) {
      return res.status(200).json({
        status: 'success',
        backups: [],
        count: 0,
        timestamp: Date.now()
      });
    }
    
    const files = fs.readdirSync(backupDir);
    const backups = files
      .filter(file => file.startsWith('backup-') && file.endsWith('.sql'))
      .map(file => {
        const filePath = path.join(backupDir, file);
        const stats = fs.statSync(filePath);
        
        try {
          const content = fs.readFileSync(filePath, 'utf8');
          const data = JSON.parse(content);
          return {
            filename: file,
            size: stats.size,
            createdAt: data.timestamp,
            createdBy: data.createdBy,
            tables: data.tables
          };
        } catch (error) {
          return {
            filename: file,
            size: stats.size,
            createdAt: stats.mtime.toISOString(),
            createdBy: 'unknown',
            tables: {}
          };
        }
      })
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    res.status(200).json({
      status: 'success',
      backups: backups,
      count: backups.length,
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('Backup list error:', error);
    res.status(500).json({
      error: 'Failed to list system backups',
      details: error.message
    });
  }
});

// Restore system from backup (admin only)
router.post('/restore', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    const { filename } = req.body;
    
    if (!filename) {
      return res.status(400).json({
        error: 'Backup filename required',
        details: 'Please provide a backup filename to restore from'
      });
    }
    
    const backupDir = path.join(__dirname, '..', '..', 'backups');
    const backupFile = path.join(backupDir, filename);
    
    if (!fs.existsSync(backupFile)) {
      return res.status(404).json({
        error: 'Backup not found',
        details: `Backup file ${filename} does not exist`
      });
    }
    
    // Check if this is a metadata-only backup
    const isMetadataOnly = filename.endsWith('.json');
    
    if (isMetadataOnly) {
      return res.status(400).json({
        error: 'Cannot restore from metadata-only backup',
        details: 'This backup contains only metadata. Please use a full database backup file (.sql) for restoration.'
      });
    }
    
    // Read metadata file if it exists
    let backupData = {};
    const metadataFile = path.join(backupDir, filename.replace('.sql', '.json'));
    if (fs.existsSync(metadataFile)) {
      try {
        const metadataContent = fs.readFileSync(metadataFile, 'utf8');
        backupData = JSON.parse(metadataContent);
      } catch (error) {
        console.warn('Failed to read metadata file:', error);
      }
    }
    
    // Get database configuration from environment
    const dbConfig = {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres'
    };
    
    // Use pg_restore for PostgreSQL restore
    const { exec } = require('child_process');
    
    // First, terminate all connections to the database
    const terminateConnectionsCommand = `psql -h ${dbConfig.host} -p ${dbConfig.port} -U ${dbConfig.user} -d postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${dbConfig.database}' AND pid <> pg_backend_pid();"`;
    
    // Then restore the database using pg_restore
    const restoreCommand = `pg_restore -h ${dbConfig.host} -p ${dbConfig.port} -U ${dbConfig.user} -d ${dbConfig.database} -c "${backupFile}"`;
    
    // Set PGPASSWORD environment variable for authentication
    const env = { ...process.env, PGPASSWORD: dbConfig.password };
    
    // Log the restore operation attempt
    await AuditLog.logChange({
      userId: req.user.id,
      action: 'system_restore_attempted',
      entityType: 'system',
      entityId: 'backup',
      oldValues: {},
      newValues: { filename, backupData },
      description: `System restore initiated from backup ${filename} by ${req.user.email}`
    });
    
    // Step 1: Terminate existing connections
    exec(terminateConnectionsCommand, { env }, async (error, stdout, stderr) => {
      if (error) {
        console.warn('Failed to terminate connections (may be normal if no connections):', error);
      }
      
      // Step 2: Restore the database
      exec(restoreCommand, { env }, async (error, stdout, stderr) => {
        if (error) {
          console.error('pg_restore error:', error);
          console.error('stderr:', stderr);
          
          // Log the restore failure
          await AuditLog.logChange({
            userId: req.user.id,
            action: 'system_restore_failed',
            entityType: 'system',
            entityId: 'backup',
            oldValues: {},
            newValues: { filename, error: error.message },
            description: `System restore failed from backup ${filename} by ${req.user.email}: ${error.message}`
          });
          
          return res.status(500).json({
            error: 'Failed to restore system',
            details: error.message,
            stderr: stderr
          });
        }
        
        // Log the successful restore
        await AuditLog.logChange({
          userId: req.user.id,
          action: 'system_restore_completed',
          entityType: 'system',
          entityId: 'backup',
          oldValues: {},
          newValues: { filename, ...backupData },
          description: `System restored successfully from backup ${filename} by ${req.user.email}`
        });
        
        res.status(200).json({
          status: 'success',
          message: 'System restored successfully',
          backup: {
            filename: filename,
            createdAt: backupData.timestamp || new Date().toISOString(),
            createdBy: backupData.createdBy || 'unknown',
            stats: backupData.tables || {},
            type: 'full_database'
          },
          timestamp: Date.now()
        });
      });
    });
  } catch (error) {
    console.error('Restore error:', error);
    res.status(500).json({
      error: 'Failed to restore system',
      details: error.message
    });
  }
});

// Toggle maintenance mode (admin only)
router.post('/maintenance', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    const { enabled, message } = req.body;
    
    const oldMaintenanceMode = systemSettings.maintenanceMode;
    systemSettings.maintenanceMode = enabled !== undefined ? enabled : !systemSettings.maintenanceMode;
    
    if (message) {
      systemSettings.maintenanceMessage = message;
    }
    
    // Log the change
    await AuditLog.logChange({
      userId: req.user.id,
      action: 'maintenance_mode_toggle',
      entityType: 'system',
      entityId: 'maintenance',
      oldValues: { maintenanceMode: oldMaintenanceMode },
      newValues: { maintenanceMode: systemSettings.maintenanceMode, message: systemSettings.maintenanceMessage },
      description: `Maintenance mode ${systemSettings.maintenanceMode ? 'enabled' : 'disabled'} by ${req.user.email}`
    });
    
    res.status(200).json({
      status: 'success',
      message: `Maintenance mode ${systemSettings.maintenanceMode ? 'enabled' : 'disabled'}`,
      maintenanceMode: systemSettings.maintenanceMode,
      maintenanceMessage: systemSettings.maintenanceMessage,
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('Maintenance mode error:', error);
    res.status(500).json({
      error: 'Failed to toggle maintenance mode',
      details: error.message
    });
  }
});

// Get system statistics (admin only)
router.get('/stats', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    const [userCount, projectCount, sprintCount, deliverableCount, auditLogCount] = await Promise.all([
      User.count(),
      Project.count(),
      Sprint.count(),
      Deliverable.count(),
      AuditLog.count()
    ]);
    
    const systemMetrics = await analyticsService.getMetrics('performance');
    
    res.status(200).json({
      status: 'success',
      statistics: {
        users: userCount,
        projects: projectCount,
        sprints: sprintCount,
        deliverables: deliverableCount,
        auditLogs: auditLogCount,
        totalEntities: userCount + projectCount + sprintCount + deliverableCount + auditLogCount
      },
      system: systemMetrics,
      settings: systemSettings,
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('System stats error:', error);
    res.status(500).json({
      error: 'Failed to get system statistics',
      details: error.message
    });
  }
});

// Clear system cache (admin only)
router.post('/cache/clear', authenticateToken, requireRole(['system_admin']), async (req, res) => {
  try {
    // Clear analytics cache
    analyticsService.clearCache();
    
    // Log the cache clearance
    await AuditLog.logChange({
      userId: req.user.id,
      action: 'system_cache_cleared',
      entityType: 'system',
      entityId: 'cache',
      oldValues: {},
      newValues: { clearedAt: new Date().toISOString() },
      description: `System cache cleared by ${req.user.email}`
    });
    
    res.status(200).json({
      status: 'success',
      message: 'System cache cleared successfully',
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('Cache clearance error:', error);
    res.status(500).json({
      error: 'Failed to clear system cache',
      details: error.message
    });
  }
});

module.exports = router;