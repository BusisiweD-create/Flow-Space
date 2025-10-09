const express = require('express');
const router = express.Router();
const { Sprint } = require('../models');

/**
 * @route GET /api/sprints
 * @desc Get all sprints with pagination
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const sprints = await Sprint.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });
    
    res.json(sprints);
  } catch (error) {
    console.error('Error fetching sprints:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/sprints/:id
 * @desc Get a specific sprint by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const sprint = await Sprint.findByPk(id, {
      include: [
        { association: 'deliverables' },
        { association: 'signoffs' },
        { association: 'audit_logs' }
      ]
    });
    
    if (!sprint) {
      return res.status(404).json({ error: 'Sprint not found' });
    }
    
    res.json(sprint);
  } catch (error) {
    console.error('Error fetching sprint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/sprints
 * @desc Create a new sprint
 * @access Private
 */
router.post('/', async (req, res) => {
  try {
    const sprintData = req.body;
    
    const sprint = await Sprint.create(sprintData);
    
    res.status(201).json(sprint);
  } catch (error) {
    console.error('Error creating sprint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/sprints/:id
 * @desc Update an existing sprint
 * @access Private
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const sprint = await Sprint.findByPk(id);
    
    if (!sprint) {
      return res.status(404).json({ error: 'Sprint not found' });
    }
    
    await sprint.update(updateData);
    
    res.json(sprint);
  } catch (error) {
    console.error('Error updating sprint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route DELETE /api/sprints/:id
 * @desc Delete a sprint
 * @access Private
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const sprint = await Sprint.findByPk(id);
    
    if (!sprint) {
      return res.status(404).json({ error: 'Sprint not found' });
    }
    
    await sprint.destroy();
    
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting sprint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;