const express = require('express');
const router = express.Router();
const analyticsService = require('../services/analyticsService');
const { Sprint } = require('../models');
const { authenticateToken, requireRole } = require('../middleware/auth');

/**
 * @route GET /api/analytics/dashboard
 * @desc Get comprehensive dashboard metrics
 * @access Private
 */
router.get('/dashboard', authenticateToken, async (req, res) => {
  try {
    const metrics = await analyticsService.getMetrics();
    res.json(metrics);
  } catch (error) {
    console.error('Error fetching dashboard metrics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/analytics/user-activity
 * @desc Get user activity metrics
 * @access Private
 */
router.get('/user-activity', authenticateToken, async (req, res) => {
  try {
    const metrics = await analyticsService.getMetrics('user_activity');
    res.json(metrics);
  } catch (error) {
    console.error('Error fetching user activity metrics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/analytics/system-usage
 * @desc Get system usage metrics
 * @access Private
 */
router.get('/system-usage', authenticateToken, async (req, res) => {
  try {
    const metrics = await analyticsService.getMetrics('system_usage');
    res.json(metrics);
  } catch (error) {
    console.error('Error fetching system usage metrics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Compatibility endpoint for performance metrics expected by frontend
router.get('/performance', authenticateToken, async (req, res) => {
  try {
    const metrics = await analyticsService.getMetrics('system_usage');
    res.json(metrics);
  } catch (error) {
    console.error('Error fetching performance metrics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/analytics/project-metrics
 * @desc Get project and deliverable metrics
 * @access Private
 */
router.get('/project-metrics', authenticateToken, async (req, res) => {
  try {
    const metrics = await analyticsService.getMetrics('project_metrics');
    res.json(metrics);
  } catch (error) {
    console.error('Error fetching project metrics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/analytics/user/:user_id
 * @desc Get analytics for a specific user
 * @access Private
 */
router.get('/user/:user_id', authenticateToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Only allow users to view their own analytics or admins
    if (req.user.id !== parseInt(user_id) && req.user.role !== 'admin') {
      return res.status(403).json({
        error: 'Not authorized',
        message: 'Not authorized to view this user\'s analytics'
      });
    }
    
    const userAnalytics = await analyticsService.getUserAnalytics(parseInt(user_id));
    res.json(userAnalytics);
  } catch (error) {
    console.error('Error fetching user analytics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/analytics/health
 * @desc Get analytics service health status
 * @access Private
 */
router.get('/health', authenticateToken, async (req, res) => {
  try {
    res.json({
      status: analyticsService._isRunning ? 'running' : 'stopped',
      last_updated: analyticsService.metricsCache?.timestamp || null
    });
  } catch (error) {
    console.error('Error fetching analytics health:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/analytics/health/public
 * @desc Get public analytics service health status (no authentication required)
 * @access Public
 */
router.get('/health/public', async (req, res) => {
  try {
    // Test that we can get metrics without authentication
    const metrics = await analyticsService.getMetrics();
    res.json({
      status: 'running',
      has_metrics: !!metrics,
      total_sprints: metrics.total_sprints || 0,
      total_deliverables: metrics.total_deliverables || 0,
      total_users: metrics.total_users || 0
    });
  } catch (error) {
    res.json({
      status: 'error',
      error: error.message
    });
  }
});

/**
 * @route GET /api/analytics/trends/daily-activity
 * @desc Get daily activity trend for charting
 * @access Private (Admin only)
 */
router.get('/trends/daily-activity', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { days = 30 } = req.query;
    
    const dailyActivity = await AuditLog.findAll({
      attributes: [
        [Sequelize.fn('DATE', Sequelize.col('timestamp')), 'date'],
        [Sequelize.fn('COUNT', Sequelize.col('id')), 'count']
      ],
      where: {
        timestamp: {
          [Sequelize.Op.gte]: new Date(Date.now() - parseInt(days) * 24 * 60 * 60 * 1000)
        }
      },
      group: [Sequelize.fn('DATE', Sequelize.col('timestamp'))],
      order: [[Sequelize.fn('DATE', Sequelize.col('timestamp')), 'ASC']]
    });
    
    const result = dailyActivity.map(item => ({
      date: item.get('date').toISOString().split('T')[0],
      count: parseInt(item.get('count'))
    }));
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching daily activity:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/analytics/trends/user-registration
 * @desc Get user registration trend for charting
 * @access Private (Admin only)
 */
router.get('/trends/user-registration', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { weeks = 12 } = req.query;
    
    const weeklyRegistrations = await User.findAll({
      attributes: [
        [Sequelize.fn('DATE_TRUNC', 'week', Sequelize.col('created_at')), 'week'],
        [Sequelize.fn('COUNT', Sequelize.col('id')), 'count']
      ],
      where: {
        created_at: {
          [Sequelize.Op.gte]: new Date(Date.now() - parseInt(weeks) * 7 * 24 * 60 * 60 * 1000)
        }
      },
      group: [Sequelize.fn('DATE_TRUNC', 'week', Sequelize.col('created_at'))],
      order: [[Sequelize.fn('DATE_TRUNC', 'week', Sequelize.col('created_at')), 'ASC']]
    });
    
    const result = weeklyRegistrations.map(item => ({
      week: item.get('week').toISOString().split('T')[0],
      count: parseInt(item.get('count'))
    }));
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching registration trend:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/velocity-trend', authenticateToken, async (req, res) => {
  try {
    const { project_id, projectKey, maxPoints = 24 } = req.query;
    const where = {};
    if (project_id) where.project_id = project_id;
    const include = [];
    // Fetch sprints with relevant fields
    const sprints = await Sprint.findAll({
      where,
      order: [["end_date", "ASC"], ["created_at", "ASC"]],
      attributes: ['id','name','start_date','end_date','planned_points','committed_points','completed_points']
    });
    const points = (sprints || []).map((s) => {
      const date = s.end_date || s.created_at || s.start_date || new Date();
      const committed = Number(s.committed_points || s.planned_points || 0);
      const completed = Number(s.completed_points || 0);
      return { id: s.id, name: s.name, date: new Date(date), committed, completed };
    });
    // Compute moving average of completed (window=3)
    const window = 3;
    const withAvg = points.map((p, i) => {
      const start = Math.max(0, i - window + 1);
      const slice = points.slice(start, i + 1);
      const avg = slice.length > 0 ? slice.reduce((sum, x) => sum + x.completed, 0) / slice.length : 0;
      return { ...p, movingAvg: Math.round(avg * 100) / 100 };
    });
    // Downsample to reduce clustering
    const max = parseInt(maxPoints) || 24;
    let sampled = withAvg;
    if (withAvg.length > max) {
      const step = Math.ceil(withAvg.length / max);
      sampled = withAvg.filter((_, idx) => idx % step === 0);
      // Ensure last point included
      if (sampled[sampled.length - 1]?.id !== withAvg[withAvg.length - 1]?.id) {
        sampled.push(withAvg[withAvg.length - 1]);
      }
    }
    // Format for frontend charting: labels and series
    const labels = sampled.map(p => (p.name ? p.name : `Sprint ${p.id}`));
    const series = {
      committed: sampled.map(p => p.committed),
      completed: sampled.map(p => p.completed),
      movingAvg: sampled.map(p => p.movingAvg)
    };
    return res.json({ success: true, data: { labels, series } });
  } catch (error) {
    console.error('Velocity trend error:', error);
    return res.status(500).json({ success: false, error: 'Failed to compute velocity trend' });
  }
});

module.exports = router;
