const express = require('express');
const router = express.Router();
const { Deliverable, DeliverableSprint } = require('../models');

/**
 * @route GET /api/deliverables
 * @desc Get all deliverables with pagination
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const deliverables = await Deliverable.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });
    
    res.json({ success: true, data: deliverables });
  } catch (error) {
    console.error('Error fetching deliverables:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/deliverables/sprint/:sprintId
 * @desc Get all deliverables for a specific sprint
 * @access Public
 */
router.get('/sprint/:sprintId', async (req, res) => {
  try {
    const { sprintId } = req.params;
    
    const deliverables = await Deliverable.findAll({
      include: [{
        association: 'contributing_sprints',
        where: { id: sprintId },
        through: { attributes: [] } // Exclude junction table attributes
      }],
      order: [['created_at', 'DESC']]
    });
    
    res.json({ success: true, data: deliverables });
  } catch (error) {
    console.error('Error fetching sprint deliverables:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/deliverables/:id
 * @desc Get a specific deliverable by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const deliverable = await Deliverable.findByPk(id, {
      include: [
        { association: 'contributing_sprints' },
        { association: 'signoffs' },
        { association: 'audit_logs' }
      ]
    });
    
    if (!deliverable) {
      return res.status(404).json({ error: 'Deliverable not found' });
    }
    
    res.json({ success: true, data: deliverable });
  } catch (error) {
    console.error('Error fetching deliverable:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/deliverables
 * @desc Create a new deliverable
 * @access Private
 */
router.post('/', async (req, res) => {
  try {
    const { sprintIds, ...deliverableData } = req.body || {};
    const deliverable = await Deliverable.create(deliverableData);

    if (Array.isArray(sprintIds) && sprintIds.length > 0) {
      const ids = sprintIds
        .map((id) => parseInt(id))
        .filter((n) => Number.isFinite(n));
      await Promise.all(
        ids.map((sprintId) =>
          DeliverableSprint.create({ deliverable_id: deliverable.id, sprint_id: sprintId })
        )
      );
    }

    res.status(201).json(deliverable);
  } catch (error) {
    console.error('Error creating deliverable:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/deliverables/:id
 * @desc Update an existing deliverable
 * @access Private
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const deliverable = await Deliverable.findByPk(id);
    
    if (!deliverable) {
      return res.status(404).json({ error: 'Deliverable not found' });
    }
    
    await deliverable.update(updateData);
    
    res.json(deliverable);
  } catch (error) {
    console.error('Error updating deliverable:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route DELETE /api/deliverables/:id
 * @desc Delete a deliverable
 * @access Private
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const deliverable = await Deliverable.findByPk(id);
    
    if (!deliverable) {
      return res.status(404).json({ error: 'Deliverable not found' });
    }
    
    await deliverable.destroy();
    
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting deliverable:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;