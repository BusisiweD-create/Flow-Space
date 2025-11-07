"use strict";

const fs = require('fs').promises;
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { Sequelize, Op } = require('sequelize');
const { AuditLog } = require('../models');

class LogLevel {
    static DEBUG = "DEBUG";
    static INFO = "INFO";
    static WARNING = "WARNING";
    static ERROR = "ERROR";
    static CRITICAL = "CRITICAL";
}

class LogCategory {
    static AUDIT = "AUDIT";
    static PERFORMANCE = "PERFORMANCE";
    static SECURITY = "SECURITY";
    static BUSINESS = "BUSINESS";
    static SYSTEM = "SYSTEM";
    static DATABASE = "DATABASE";
    static API = "API";
    static WEBSOCKET = "WEBSOCKET";
}

class LoggingService {
    constructor() {
        this.metrics = {
            requestCount: 0,
            errorCount: 0,
            avgResponseTime: 0.0,
            activeRequests: 0,
            lastCleanup: new Date()
        };
        this.requestTimes = new Map();
        this.requestId = '';
        this.userId = '';
        
        this.setupLogging();
    }
    
    setupLogging() {
        // Basic console logging setup
        // In production, you might want to use a proper logging library like winston
        console.log('Logging service initialized');
    }
    
    async start() {
        console.log('Logging service started');
    }
    
    async stop() {
        console.log('Logging service stopped');
    }
    
    log(level, category, message, durationMs = null, metadata = null, error = null, stackTrace = null) {
        const logEntry = {
            timestamp: new Date(),
            level,
            category,
            message,
            requestId: this.requestId,
            userId: this.userId,
            durationMs,
            metadata,
            error,
            stackTrace
        };
        
        this.writeLog(logEntry);
        
        // Also create audit log for certain categories
        if ([LogCategory.AUDIT, LogCategory.SECURITY, LogCategory.BUSINESS].includes(category)) {
            this.createAuditLog(logEntry);
        }
    }
    
    writeLog(logEntry) {
        // Write to console with structured format
        const logData = {
            timestamp: logEntry.timestamp.toISOString(),
            level: logEntry.level,
            category: logEntry.category,
            message: logEntry.message,
            requestId: logEntry.requestId,
            userId: logEntry.userId
        };
        
        if (logEntry.durationMs) {
            logData.durationMs = logEntry.durationMs;
        }
        
        if (logEntry.metadata) {
            logData.metadata = logEntry.metadata;
        }
        
        // Use appropriate console method based on log level
        const consoleMethod = {
            [LogLevel.DEBUG]: console.debug,
            [LogLevel.INFO]: console.info,
            [LogLevel.WARNING]: console.warn,
            [LogLevel.ERROR]: console.error,
            [LogLevel.CRITICAL]: console.error
        }[logEntry.level] || console.log;
        
        consoleMethod(JSON.stringify(logData));
    }
    
    async createAuditLog(logEntry) {
        try {
            const auditLogData = {
                entityType: "system",
                entityId: 0,
                action: `${logEntry.category}_${logEntry.level}`,
                user: logEntry.userId,
                details: JSON.stringify({
                    message: logEntry.message,
                    requestId: logEntry.requestId,
                    metadata: logEntry.metadata || {}
                })
            };
            
            await AuditLog.create(auditLogData);
        } catch (error) {
            console.error('Failed to create audit log:', error);
        }
    }
    
    startRequest(requestId, userId = null) {
        this.requestId = requestId;
        if (userId) {
            this.userId = userId;
        }
        
        this.requestTimes.set(requestId, Date.now());
        this.metrics.activeRequests++;
        this.metrics.requestCount++;
    }
    
    endRequest(requestId, statusCode) {
        if (this.requestTimes.has(requestId)) {
            const startTime = this.requestTimes.get(requestId);
            const duration = Date.now() - startTime;
            
            this.metrics.activeRequests--;
            
            if (statusCode >= 400) {
                this.metrics.errorCount++;
            }
            
            // Log request completion
            this.log(
                statusCode < 400 ? LogLevel.INFO : LogLevel.ERROR,
                LogCategory.API,
                `Request completed: ${statusCode}`,
                duration,
                { statusCode, durationMs: duration }
            );
            
            this.requestTimes.delete(requestId);
        }
    }
    
    getMetrics() {
        return { ...this.metrics };
    }
    
    async getRecentLogs(limit = 100) {
        try {
            const logs = await AuditLog.findAll({
                order: [['timestamp', 'DESC']],
                limit: limit
            });
            
            return logs.map(log => ({
                timestamp: log.timestamp,
                action: log.action,
                user: log.user,
                details: log.details ? JSON.parse(log.details) : {}
            }));
        } catch (error) {
            console.error('Failed to get recent logs:', error);
            return [];
        }
    }
}

// Global logging service instance
const loggingService = new LoggingService();

module.exports = {
    LoggingService,
    LogLevel,
    LogCategory,
    loggingService
};