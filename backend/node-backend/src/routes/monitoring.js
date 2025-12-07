"use strict";

const express = require('express');
const { Sequelize, Op } = require('sequelize');
const { authenticateToken } = require('../middleware/auth');
const { User, Deliverable, Sprint, Signoff, AuditLog } = require('../models');
const analyticsService = require('../services/analyticsService');
const { loggingService } = require('../services/loggingService');

const router = express.Router();

// Health check endpoint
router.get('/health', async (req, res) => {
    try {
        // Test database connection
        await User.findOne();
        
        res.status(200).json({
            status: 'healthy',
            database: 'connected',
            timestamp: Date.now()
        });
        
    } catch (error) {
        console.error('Health check failed:', error);
        res.status(503).json({
            status: 'unhealthy',
            database: 'disconnected',
            error: `Database connection failed: ${error.message}`,
            timestamp: Date.now()
        });
    }
});

// Get system performance metrics
router.get('/metrics/system', authenticateToken, async (req, res) => {
    try {
        const metrics = await analyticsService.getMetrics('performance');
        
        res.status(200).json({
            status: 'success',
            metrics: metrics,
            timestamp: Date.now()
        });
        
    } catch (error) {
        console.error('System metrics error:', error);
        res.status(500).json({
            error: 'Failed to get system metrics',
            details: error.message
        });
    }
});

// Get application performance metrics
router.get('/metrics/application', authenticateToken, async (req, res) => {
    try {
        const responseTimes = analyticsService.performanceMetrics.responseTimes || [];
        const errorRates = analyticsService.performanceMetrics.errorRates || [];
        
        let avgResponseTime = 0;
        let maxResponseTime = 0;
        let minResponseTime = 0;
        let errorCount = 0;
        let errorRate = 0;
        
        if (responseTimes.length > 0) {
            avgResponseTime = responseTimes.reduce((sum, time) => sum + time, 0) / responseTimes.length;
            maxResponseTime = Math.max(...responseTimes);
            minResponseTime = Math.min(...responseTimes);
        }
        
        if (errorRates.length > 0) {
            errorCount = errorRates.reduce((sum, rate) => sum + rate, 0);
            errorRate = (errorCount / errorRates.length) * 100;
        }
        
        res.status(200).json({
            status: 'success',
            metrics: {
                response_times: {
                    count: responseTimes.length,
                    average_ms: avgResponseTime * 1000,
                    max_ms: maxResponseTime * 1000,
                    min_ms: minResponseTime * 1000,
                    p95_ms: responseTimes.length > 0 ? 
                        responseTimes.sort()[Math.floor(responseTimes.length * 0.95)] * 1000 : 0
                },
                error_rates: {
                    total_requests: errorRates.length,
                    error_count: errorCount,
                    error_rate_percent: errorRate
                },
                throughput: {
                    requests_per_minute: errorRates.length > 0 ? 
                        errorRates.length / (analyticsService.cacheTtl / 60) : 0
                }
            },
            timestamp: Date.now()
        });
        
    } catch (error) {
        console.error('Application metrics error:', error);
        res.status(500).json({
            error: 'Failed to get application metrics',
            details: error.message
        });
    }
});

// Get database metrics
router.get('/metrics/database', authenticateToken, async (req, res) => {
    try {
        const [userCount, deliverableCount, sprintCount, signoffCount, auditLogCount] = await Promise.all([
            User.count(),
            Deliverable.count(),
            Sprint.count(),
            Signoff.count(),
            AuditLog.count()
        ]);
        
        res.status(200).json({
            status: 'success',
            metrics: {
                users: userCount,
                deliverables: deliverableCount,
                sprints: sprintCount,
                signoffs: signoffCount,
                audit_logs: auditLogCount,
                total_entities: userCount + deliverableCount + sprintCount + signoffCount + auditLogCount
            },
            timestamp: Date.now()
        });
        
    } catch (error) {
        console.error('Database metrics error:', error);
        res.status(500).json({
            error: 'Failed to get database metrics',
            details: error.message
        });
    }
});

// Get recent logs
router.get('/logs/recent', authenticateToken, async (req, res) => {
    try {
        const { limit = 50 } = req.query;
        const logs = await loggingService.getRecentLogs(parseInt(limit));
        
        res.status(200).json({
            status: 'success',
            logs: logs,
            count: logs.length,
            timestamp: Date.now()
        });
        
    } catch (error) {
        console.error('Recent logs error:', error);
        res.status(500).json({
            error: 'Failed to get logs',
            details: error.message
        });
    }
});

// Get comprehensive system status
router.get('/status/comprehensive', authenticateToken, async (req, res) => {
    try {
        // Get all metrics concurrently
        const [systemMetrics, userCount, deliverableCount, sprintCount] = await Promise.all([
            analyticsService.getMetrics('performance'),
            User.count(),
            Deliverable.count(),
            Sprint.count()
        ]);
        
        const responseTimes = analyticsService.performanceMetrics.responseTimes || [];
        const errorRates = analyticsService.performanceMetrics.errorRates || [];
        
        let avgResponseTime = 0;
        let errorCount = 0;
        let errorRate = 0;
        
        if (responseTimes.length > 0) {
            avgResponseTime = responseTimes.reduce((sum, time) => sum + time, 0) / responseTimes.length;
        }
        
        if (errorRates.length > 0) {
            errorCount = errorRates.reduce((sum, rate) => sum + rate, 0);
            errorRate = (errorCount / errorRates.length) * 100;
        }
        
        res.status(200).json({
            status: 'success',
            system: systemMetrics,
            database: {
                users: userCount,
                deliverables: deliverableCount,
                sprints: sprintCount,
                total_entities: userCount + deliverableCount + sprintCount
            },
            application: {
                response_time_avg_ms: avgResponseTime * 1000,
                error_rate_percent: errorRate,
                total_requests: errorRates.length,
                error_count: errorCount
            },
            services: {
                analytics_service: analyticsService.isRunning,
                logging_service: true, // Logging service is always running in Node.js
                uptime_seconds: (Date.now() - analyticsService.startTime) / 1000
            },
            timestamp: Date.now()
        });
        
    } catch (error) {
        console.error('Comprehensive status error:', error);
        res.status(500).json({
            error: 'Failed to get comprehensive status',
            details: error.message
        });
    }
});

// Get system alerts
router.get('/alerts', authenticateToken, async (req, res) => {
    try {
        const systemMetrics = await analyticsService.getMetrics('performance');
        const alerts = [];
        
        // Check for high CPU usage
        if (systemMetrics.cpu_percent > 80) {
            alerts.push({
                level: 'warning',
                message: `High CPU usage: ${systemMetrics.cpu_percent}%`,
                metric: 'cpu_percent'
            });
        }
        
        // Check for high memory usage
        if (systemMetrics.memory_percent > 85) {
            alerts.push({
                level: 'warning',
                message: `High memory usage: ${systemMetrics.memory_percent}%`,
                metric: 'memory_percent'
            });
        }
        
        // Check for low disk space
        if (systemMetrics.disk_usage && systemMetrics.disk_usage.percent > 90) {
            alerts.push({
                level: 'warning',
                message: `Low disk space: ${systemMetrics.disk_usage.percent}% used`,
                metric: 'disk_usage'
            });
        }
        
        res.status(200).json({
            status: 'success',
            alerts: alerts,
            count: alerts.length,
            timestamp: Date.now()
        });
        
    } catch (error) {
        console.error('System alerts error:', error);
        res.status(500).json({
            error: 'Failed to get system alerts',
            details: error.message
        });
    }
});

module.exports = router;